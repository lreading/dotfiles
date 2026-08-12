#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
TEST_DIR="$(mktemp -d)"
readonly TEST_DIR
readonly MOCK_BIN="${TEST_DIR}/bin"
readonly CALLS="${TEST_DIR}/calls"
readonly CONFIG="${TEST_DIR}/arch-autosnapshot.conf"
readonly CONFIG_V2="${TEST_DIR}/arch-autosnapshot-v2.conf"

cleanup() {
  find "$TEST_DIR" -depth -mindepth 1 -delete
  rmdir "$TEST_DIR"
}
trap cleanup EXIT

mkdir -p "$MOCK_BIN"

cat >"${MOCK_BIN}/zpool" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "list" ]]; then
  printf '%s\n' "${TEST_POOL_CAPACITY:-13}%"
  exit 0
fi
exit 64
EOF

cat >"${MOCK_BIN}/zfs" <<'EOF'
#!/usr/bin/env bash
printf 'zfs' >>"$TEST_CALLS"
printf ' %q' "$@" >>"$TEST_CALLS"
printf '\n' >>"$TEST_CALLS"
if [[ "$1" == "list" ]]; then
  if [[ " $* " == *" -o name "* ]]; then
    dataset="${*: -1}"
    printf '%s\n' "${TEST_SNAPSHOT_LIST:-}" | grep -F "${dataset}@" || true
  elif [[ "${*: -1}" == *@* ]]; then
    exit 1
  fi
  exit 0
fi
EOF

cat >"${MOCK_BIN}/logger" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

chmod +x "${MOCK_BIN}/zpool" "${MOCK_BIN}/zfs" "${MOCK_BIN}/logger"

cat >"$CONFIG" <<'EOF'
POOL=zroot
CAPACITY_WARN=70
CAPACITY_CRITICAL=80
PRUNE_EXPIRED=no
PREPACMAN_KEEP=3
PREPACMAN_DATASET=zroot/ROOT/arch
declare -A SNAPSHOT_POLICY_DATASETS=(
  ["default"]="zroot/ROOT/arch:n zroot/home:n zroot/local/development:n"
)
declare -A SNAPSHOT_POLICY_KEEP=(
  ["default|10min"]=4
)
EOF

export TEST_CALLS="$CALLS"
export ZFS_AUTOSNAPSHOT_CONFIG="$CONFIG"

PATH="${MOCK_BIN}:$PATH" \
  "${SCRIPT_DIR}/system/usr/local/sbin/zfs-autosnapshot" default--10min

grep -E '^zfs snapshot zroot/ROOT/arch@.* zroot/home@.* zroot/local/development@' "$CALLS" >/dev/null
if grep -E -- '(^| )-r( |$)|zfs destroy' "$CALLS" >/dev/null; then
  printf '%s\n' "autosnapshot used recursive or destructive behavior" >&2
  exit 1
fi

: >"$CALLS"
PATH="${MOCK_BIN}:$PATH" \
  "${SCRIPT_DIR}/system/usr/local/sbin/zfs-prepacman-snapshot"
grep -E '^zfs snapshot zroot/ROOT/arch@pre_update_' "$CALLS" >/dev/null
if grep -E -- '(^| )-r( |$)|zfs destroy|zroot/home@' "$CALLS" >/dev/null; then
  printf '%s\n' "pre-upgrade snapshot escaped the root dataset" >&2
  exit 1
fi

: >"$CALLS"
if TEST_POOL_CAPACITY=80 PATH="${MOCK_BIN}:$PATH" \
  "${SCRIPT_DIR}/system/usr/local/sbin/zfs-autosnapshot" default--10min; then
  printf '%s\n' "critical-capacity snapshot unexpectedly succeeded" >&2
  exit 1
else
  status="$?"
  [[ "$status" == "75" ]] || exit "$status"
fi
if grep -E '^zfs snapshot' "$CALLS" >/dev/null; then
  printf '%s\n' "snapshot was created at critical capacity" >&2
  exit 1
fi

cat >"$CONFIG_V2" <<'EOF'
POOL=zroot
CAPACITY_WARN=70
CAPACITY_CRITICAL=80
PRUNE_EXPIRED=yes
SNAPSHOT_PREFIX=autosnap_v2
PREPACMAN_PREFIX=pre_update_v2
PREPACMAN_KEEP=1
PREPACMAN_DATASET=zroot/ROOT/arch
declare -A SNAPSHOT_POLICY_DATASETS=(
  ["default"]="zroot/ROOT/arch:n zroot/home:n zroot/local/development:n"
)
declare -A SNAPSHOT_POLICY_KEEP=(
  ["default|10min"]=1
)
EOF

readonly SNAPSHOT_LIST=$'zroot/ROOT/arch@autosnap_default_10min_legacy\nzroot/ROOT/arch@autosnap_v2_default_10min_old\nzroot/ROOT/arch@autosnap_v2_default_10min_new\nzroot/home@autosnap_default_10min_legacy\nzroot/home@autosnap_v2_default_10min_old\nzroot/home@autosnap_v2_default_10min_new\nzroot/local/development@autosnap_default_10min_legacy\nzroot/local/development@autosnap_v2_default_10min_old\nzroot/local/development@autosnap_v2_default_10min_new'

: >"$CALLS"
TEST_SNAPSHOT_LIST="$SNAPSHOT_LIST" \
ZFS_AUTOSNAPSHOT_CONFIG="$CONFIG_V2" \
PATH="${MOCK_BIN}:$PATH" \
  "${SCRIPT_DIR}/system/usr/local/sbin/zfs-autosnapshot" default--10min

if grep -E '^zfs destroy .*@autosnap_default_' "$CALLS" >/dev/null; then
  printf '%s\n' "v2 retention selected a legacy autosnapshot for destruction" >&2
  exit 1
fi
[[ "$(grep -c -E '^zfs destroy .*@autosnap_v2_default_10min_old$' "$CALLS")" == "3" ]]

: >"$CALLS"
TEST_SNAPSHOT_LIST=$'zroot/ROOT/arch@pre_update_legacy\nzroot/ROOT/arch@pre_update_v2_old\nzroot/ROOT/arch@pre_update_v2_new' \
ZFS_AUTOSNAPSHOT_CONFIG="$CONFIG_V2" \
PATH="${MOCK_BIN}:$PATH" \
  "${SCRIPT_DIR}/system/usr/local/sbin/zfs-prepacman-snapshot"

if grep -E '^zfs destroy .*@pre_update_legacy$' "$CALLS" >/dev/null; then
  printf '%s\n' "v2 retention selected a legacy pre-upgrade snapshot for destruction" >&2
  exit 1
fi
grep -E '^zfs destroy zroot/ROOT/arch@pre_update_v2_old$' "$CALLS" >/dev/null

printf '%s\n' "snapshot policy tests passed"
