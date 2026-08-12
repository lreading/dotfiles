#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly SYSTEM_SOURCE="${SCRIPT_DIR}/system"
readonly STATE_DIR="/var/lib/arch-zfs-reconcile"
readonly BACKUP_ROOT="/var/backups/arch-zfs-reconcile"
readonly ROOT_DATASET="zroot/ROOT/arch"
readonly HOME_DATASET="zroot/home"
readonly DEVELOPMENT_DATASET="zroot/local/development"
readonly CONTAINER_PARENT="${ROOT_DATASET}/volatile"
readonly DOCKER_DATASET="${CONTAINER_PARENT}/docker"
readonly CONTAINERD_DATASET="${CONTAINER_PARENT}/containerd"
readonly DEVELOPMENT_VOLATILE="${DEVELOPMENT_DATASET}/volatile"
readonly TMP_DATASET="${DEVELOPMENT_VOLATILE}/tmp"
readonly CONTAINER_QUOTA="40G"
readonly TMP_QUOTA="50G"
readonly ROOT_QUOTA="175G"
readonly HOME_QUOTA="250G"
readonly DEVELOPMENT_QUOTA="400G"
readonly -a SNAPSHOT_TIMERS=(
  zfs-autosnapshot-default--10min.timer
  zfs-autosnapshot-default--hourly.timer
  zfs-autosnapshot-default--daily.timer
  zfs-autosnapshot-default--weekly.timer
  zfs-autosnapshot-default--monthly.timer
)

usage() {
  cat <<'EOF'
Usage: reconcile-existing-zfs.sh COMMAND

Commands:
  audit          Show current topology, quotas, snapshot use, and Docker use.
  deploy-policy  Install the nonrecursive policy without migrating data.
  deploy-quotas  Cap root, home, and development while preserving pool headroom.
  apply          Deploy policy and migrate Docker, containerd, and development tmp.
  verify         Verify the deployed policy, datasets, mounts, services, and timers.

The apply command preserves the original directories as timestamped rollback
copies. It does not destroy legacy snapshots. New snapshots use a separate v2
namespace so retention can prune them without touching the legacy history.
EOF
}

say() {
  printf '%s\n' "$*"
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_root() {
  ((EUID == 0)) || die "run this command with sudo"
}

require_commands() {
  local command_name
  for command_name in "$@"; do
    command -v "$command_name" >/dev/null || die "missing required command: $command_name"
  done
}

validate_topology() {
  local dataset
  for dataset in "$ROOT_DATASET" "$HOME_DATASET" "$DEVELOPMENT_DATASET"; do
    zfs list -H -t filesystem "$dataset" >/dev/null \
      || die "required dataset is missing: $dataset"
  done

  [[ "$(zfs get -H -o value mountpoint "$ROOT_DATASET")" == "/" ]] \
    || die "$ROOT_DATASET is not mounted at /"
  [[ "$(zfs get -H -o value mountpoint "$HOME_DATASET")" == "/home" ]] \
    || die "$HOME_DATASET is not mounted at /home"
  [[ "$(zfs get -H -o value mountpoint "$DEVELOPMENT_DATASET")" == "/local/development" ]] \
    || die "$DEVELOPMENT_DATASET is not mounted at /local/development"
}

audit() {
  validate_topology
  zpool status -x zroot
  zpool list -o name,size,alloc,free,cap,frag,health zroot
  zfs list -o name,used,avail,refer,usedsnap,mountpoint,quota -r zroot
  zfs list -H -t snapshot -o name | awk -F@ '
    { count[$1]++; total++ }
    END {
      for (dataset in count) print count[dataset], dataset
      print total, "TOTAL"
    }
  ' | sort -k2
  docker system df 2>/dev/null || true
}

stop_snapshot_timers() {
  systemctl stop "${SNAPSHOT_TIMERS[@]}"
}

start_snapshot_timers() {
  systemctl start "${SNAPSHOT_TIMERS[@]}"
}

backup_policy_files() {
  local timestamp="$1"
  local backup_dir="${BACKUP_ROOT}/${timestamp}"
  local path
  local relative
  local -a paths=(
    /etc/zfs/arch-autosnapshot.conf
    /usr/local/sbin/zfs-autosnapshot
    /usr/local/sbin/zfs-prepacman-snapshot
    /etc/pacman.d/hooks/zfs-snapshot-pre.hook
  )

  mkdir -p "$backup_dir"
  for path in "${paths[@]}"; do
    [[ -e "$path" ]] || continue
    relative="${path#/}"
    install -Dm"$(stat -c '%a' "$path")" "$path" "${backup_dir}/${relative}"
  done
  say "Policy backup: $backup_dir"
}

install_policy_files() {
  install -Dm644 \
    "${SYSTEM_SOURCE}/etc/zfs/arch-autosnapshot.conf" \
    /etc/zfs/arch-autosnapshot.conf
  install -Dm755 \
    "${SYSTEM_SOURCE}/usr/local/sbin/zfs-autosnapshot" \
    /usr/local/sbin/zfs-autosnapshot
  install -Dm755 \
    "${SYSTEM_SOURCE}/usr/local/sbin/zfs-prepacman-snapshot" \
    /usr/local/sbin/zfs-prepacman-snapshot
  install -Dm644 \
    "${SYSTEM_SOURCE}/etc/pacman.d/hooks/zfs-snapshot-pre.hook" \
    /etc/pacman.d/hooks/zfs-snapshot-pre.hook
}

deploy_policy() {
  local timestamp
  require_root
  validate_topology
  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"

  stop_snapshot_timers
  backup_policy_files "$timestamp"
  install_policy_files
  systemctl daemon-reload
  start_snapshot_timers

  say "Installed nonrecursive v2 policy; legacy snapshots are outside its pruning namespace."
}

ensure_parent_dataset() {
  local dataset="$1"
  local quota="$2"

  if ! zfs list -H -t filesystem "$dataset" >/dev/null 2>&1; then
    zfs create -o mountpoint=none -o "quota=${quota}" "$dataset"
  fi
  zfs set mountpoint=none "quota=${quota}" "$dataset"
}

verify_rsync_copy() {
  local source="$1"
  local destination="$2"
  local report="$3"

  rsync -aHAXScni --numeric-ids --delete "${source}/" "${destination}/" >"$report"
  if [[ -s "$report" ]]; then
    sed -n '1,80p' "$report" >&2
    die "copy verification failed for $source; full report: $report"
  fi
}

migrate_directory() {
  local dataset="$1"
  local source="$2"
  local timestamp="$3"
  local mode uid gid parent base staging backup report

  if zfs list -H -t filesystem "$dataset" >/dev/null 2>&1; then
    [[ "$(zfs get -H -o value mountpoint "$dataset")" == "$source" ]] \
      || die "$dataset exists with an unexpected mountpoint"
    mountpoint -q "$source" || die "$dataset is not mounted at $source"
    say "Already migrated: $source"
    return
  fi

  [[ -d "$source" ]] || die "source directory is missing: $source"
  mode="$(stat -c '%a' "$source")"
  uid="$(stat -c '%u' "$source")"
  gid="$(stat -c '%g' "$source")"
  parent="$(dirname -- "$source")"
  base="$(basename -- "$source")"
  staging="${parent}/.${base}.zfs-new-${timestamp}"
  backup="${parent}/${base}.pre-zfs-migration-${timestamp}"
  report="${STATE_DIR}/${base}-${timestamp}.rsync-check"

  [[ ! -e "$staging" && ! -e "$backup" ]] \
    || die "migration staging or backup path already exists for $source"

  mkdir -p "$staging"
  zfs create -o "mountpoint=${staging}" "$dataset"
  rsync -aHAXS --numeric-ids "${source}/" "${staging}/"
  verify_rsync_copy "$source" "$staging" "$report"

  zfs unmount "$dataset"
  mv "$source" "$backup"
  mkdir -p "$source"
  chown "$uid:$gid" "$source"
  chmod "$mode" "$source"
  zfs set "mountpoint=${source}" "$dataset"
  mountpoint -q "$source" || die "failed to mount $dataset at $source"
  chown "$uid:$gid" "$source"
  chmod "$mode" "$source"
  verify_rsync_copy "$backup" "$source" "$report"
  rmdir "$staging" 2>/dev/null || true

  printf '%s\t%s\t%s\n' "$dataset" "$source" "$backup" \
    >>"${STATE_DIR}/rollback-directories.tsv"
  say "Migrated $source; rollback copy: $backup"
}

create_safety_snapshots() {
  local timestamp="$1"
  local dataset
  local snapshot_name="pre_volatile_migration_${timestamp}"

  for dataset in "$ROOT_DATASET" "$HOME_DATASET" "$DEVELOPMENT_DATASET"; do
    if ! zfs list -H -t snapshot "${dataset}@${snapshot_name}" >/dev/null 2>&1; then
      zfs snapshot "${dataset}@${snapshot_name}"
    fi
  done
}

deploy_guardrail_quotas() {
  require_root
  validate_topology
  zfs set "quota=${ROOT_QUOTA}" "$ROOT_DATASET"
  zfs set "quota=${HOME_QUOTA}" "$HOME_DATASET"
  zfs set "quota=${DEVELOPMENT_QUOTA}" "$DEVELOPMENT_DATASET"
  say "Applied root/home/development guardrail quotas."
}

apply_migration() {
  local timestamp
  local docker_was_active="no"
  local containerd_was_active="no"
  local timers_stopped="no"
  local services_stopped="no"

  cleanup_failed_migration() {
    local status="$?"
    if ((status == 0)); then
      return
    fi
    if [[ "$timers_stopped" == "yes" ]]; then
      systemctl start "${SNAPSHOT_TIMERS[@]}" >/dev/null 2>&1 || true
    fi
    if [[ "$services_stopped" == "yes" ]]; then
      printf '%s\n' \
        "Migration stopped after the container services were shut down." \
        "Docker and containerd were intentionally left stopped for inspection." >&2
    fi
  }
  trap cleanup_failed_migration EXIT

  require_root
  require_commands rsync zfs zpool docker systemctl mountpoint
  validate_topology
  [[ -z "$(docker ps -q)" ]] || die "stop all running containers before migration"

  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
  mkdir -p "$STATE_DIR"
  docker ps -a --no-trunc >"${STATE_DIR}/docker-containers-before-${timestamp}.txt"
  docker image ls --no-trunc --digests >"${STATE_DIR}/docker-images-before-${timestamp}.txt"

  systemctl is-active --quiet docker && docker_was_active="yes"
  systemctl is-active --quiet containerd && containerd_was_active="yes"

  stop_snapshot_timers
  timers_stopped="yes"
  backup_policy_files "$timestamp"
  install_policy_files
  create_safety_snapshots "$timestamp"

  systemctl stop docker.service docker.socket containerd.service
  services_stopped="yes"

  ensure_parent_dataset "$CONTAINER_PARENT" "$CONTAINER_QUOTA"
  migrate_directory "$DOCKER_DATASET" /var/lib/docker "$timestamp"
  migrate_directory "$CONTAINERD_DATASET" /var/lib/containerd "$timestamp"

  ensure_parent_dataset "$DEVELOPMENT_VOLATILE" "$TMP_QUOTA"
  migrate_directory "$TMP_DATASET" /local/development/tmp "$timestamp"
  deploy_guardrail_quotas

  if [[ "$containerd_was_active" == "yes" || "$docker_was_active" == "yes" ]]; then
    systemctl start containerd.service
  fi
  if [[ "$docker_was_active" == "yes" ]]; then
    systemctl start docker.service
  fi
  services_stopped="no"

  docker info >/dev/null
  start_snapshot_timers
  timers_stopped="no"
  verify
  trap - EXIT

  say "Migration complete. Rollback directories were retained."
  say "Only v2 snapshots are eligible for automatic retention pruning."
}

verify() {
  local dataset expected_mount
  local -a checks=(
    "${DOCKER_DATASET}:/var/lib/docker"
    "${CONTAINERD_DATASET}:/var/lib/containerd"
    "${TMP_DATASET}:/local/development/tmp"
  )

  validate_topology
  ! rg -n 'snapshot[[:space:]]+-r|destroy[[:space:]]+-r|:r([[:space:]]|$)' \
    /etc/zfs/arch-autosnapshot.conf \
    /usr/local/sbin/zfs-autosnapshot \
    /usr/local/sbin/zfs-prepacman-snapshot \
    || die "recursive snapshot logic is still installed"

  grep -Fx 'PRUNE_EXPIRED=yes' /etc/zfs/arch-autosnapshot.conf >/dev/null \
    || die "v2 retention pruning is not enabled"
  grep -Fx 'SNAPSHOT_PREFIX=autosnap_v2' /etc/zfs/arch-autosnapshot.conf >/dev/null \
    || die "the isolated autosnapshot namespace is not configured"
  grep -Fx 'PREPACMAN_PREFIX=pre_update_v2' /etc/zfs/arch-autosnapshot.conf >/dev/null \
    || die "the isolated pre-upgrade namespace is not configured"

  for check in "${checks[@]}"; do
    dataset="${check%%:*}"
    expected_mount="${check#*:}"
    zfs list -H -t filesystem "$dataset" >/dev/null \
      || die "missing migrated dataset: $dataset"
    [[ "$(zfs get -H -o value mountpoint "$dataset")" == "$expected_mount" ]] \
      || die "unexpected mountpoint for $dataset"
    mountpoint -q "$expected_mount" || die "$expected_mount is not mounted"
  done

  [[ "$(zfs get -H -o value quota "$CONTAINER_PARENT")" == "$CONTAINER_QUOTA" ]] \
    || die "unexpected container quota"
  [[ "$(zfs get -H -o value quota "$DEVELOPMENT_VOLATILE")" == "$TMP_QUOTA" ]] \
    || die "unexpected development tmp quota"
  [[ "$(zfs get -H -o value quota "$ROOT_DATASET")" == "$ROOT_QUOTA" ]] \
    || die "unexpected root quota"
  [[ "$(zfs get -H -o value quota "$HOME_DATASET")" == "$HOME_QUOTA" ]] \
    || die "unexpected home quota"
  [[ "$(zfs get -H -o value quota "$DEVELOPMENT_DATASET")" == "$DEVELOPMENT_QUOTA" ]] \
    || die "unexpected development quota"

  docker info >/dev/null
  zpool status -x zroot
  zfs list -o name,used,avail,refer,mountpoint,quota -r zroot
  systemctl list-timers --all --no-pager | grep zfs-autosnapshot
  say "Verification passed."
}

main() {
  local command_name="${1:-}"

  require_commands awk grep rg sed sort stat zfs zpool
  case "$command_name" in
    audit) audit ;;
    deploy-policy) deploy_policy ;;
    deploy-quotas) deploy_guardrail_quotas ;;
    apply) apply_migration ;;
    verify) verify ;;
    -h|--help|help|'') usage ;;
    *) usage >&2; exit 64 ;;
  esac
}

main "$@"
