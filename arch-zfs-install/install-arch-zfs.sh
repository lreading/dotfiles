#!/usr/bin/env bash
set -Eeuo pipefail
set +x

TTY=/dev/tty
INSTALL_RUN_DIR=/run/arch-zfs-install
ZFS_KEYFILE="${INSTALL_RUN_DIR}/zfs.key"
TARGET=/mnt
POOL=zroot

DISK_COUNT=""
HOSTNAME="arch-zfs"
TIMEZONE="America/New_York"
LOCALE="en_US.UTF-8"
KEYMAP="us"
MICROCODE="none"
INSTALL_SSH="no"
CREATE_USER="no"
NEW_USERNAME=""
NEW_USER_SUDO="no"

ROOT_PASSWORD=""
ZFS_PASSPHRASE=""
NEW_USER_PASSWORD=""
ROOT_HASH=""
NEW_USER_HASH=""

declare -a DISKS=()
declare -a ESP_PARTS=()
declare -a SWAP_PARTS=()
declare -a ZFS_PARTS=()
declare -a SELECTABLE_DISKS=()
declare -a ADDITIONAL_LOCAL_DATASETS=()
declare -A ADDITIONAL_LOCAL_SEPARATE_POLICY=()
declare -A ADDITIONAL_LOCAL_POLICY_KEEP=()
declare -a SNAPSHOT_TIMER_UNITS=()
SNAPSHOT_USE_RECURSIVE_DEFAULT="yes"
EFI_DEVICE=""

say() {
  printf '%s\n' "$*" > "$TTY"
}

die() {
  say "ERROR: $*"
  exit 1
}

cleanup() {
  rm -f "$ZFS_KEYFILE" 2>/dev/null || true
  unset ROOT_PASSWORD ZFS_PASSPHRASE NEW_USER_PASSWORD ROOT_HASH NEW_USER_HASH
}
trap cleanup EXIT

require_tty() {
  [[ -r "$TTY" && -w "$TTY" ]] || die "A controlling TTY is required. This script is safe for curl | bash, but it must be run interactively."
}

require_root() {
  [[ "${EUID}" -eq 0 ]] || die "Run as root from the archzfs-lts ISO."
}

require_uefi() {
  [[ -d /sys/firmware/efi/efivars ]] || die "UEFI firmware is required. Legacy BIOS installs are intentionally unsupported."
}

require_arch_iso_tools() {
  local missing=()
  local cmd
  for cmd in bash pacman lsblk blkid findmnt sgdisk partprobe udevadm wipefs mkfs.vfat mdadm pacstrap genfstab arch-chroot zpool zfs zgenhostid openssl curl; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done

  if ((${#missing[@]} == 0)); then
    return
  fi

  say "Installing missing live ISO tools: ${missing[*]}"
  pacman -Sy --needed --noconfirm arch-install-scripts gptfdisk dosfstools mdadm curl openssl

  missing=()
  for cmd in bash pacman lsblk blkid findmnt sgdisk partprobe udevadm wipefs mkfs.vfat mdadm pacstrap genfstab arch-chroot zpool zfs zgenhostid openssl curl; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  ((${#missing[@]} == 0)) || die "Missing required commands after package install: ${missing[*]}. Use an archzfs-lts ISO."
}

curl_retry() {
  local url="$1"
  local output="$2"
  local attempt=1
  local max_attempts=5
  local delay=2

  while true; do
    if curl --fail --location --show-error --connect-timeout 15 --retry 0 "$url" -o "$output"; then
      return 0
    fi

    if ((attempt >= max_attempts)); then
      die "Failed to download ${url} after ${max_attempts} attempts."
    fi

    say "Download failed for ${url}; retrying in ${delay}s (${attempt}/${max_attempts})..."
    sleep "$delay"
    attempt=$((attempt + 1))
    delay=$((delay * 2))
  done
}

require_clean_target() {
  if findmnt -R "$TARGET" >/dev/null 2>&1; then
    die "${TARGET} already has mounted filesystems. Unmount them before running the installer."
  fi
}

ask_required() {
  local prompt="$1"
  local var_name="$2"
  local value=""

  while [[ -z "$value" ]]; do
    printf '%s: ' "$prompt" > "$TTY"
    IFS= read -r value < "$TTY"
  done

  printf -v "$var_name" '%s' "$value"
}

ask_default() {
  local prompt="$1"
  local default="$2"
  local var_name="$3"
  local value=""

  printf '%s [%s]: ' "$prompt" "$default" > "$TTY"
  IFS= read -r value < "$TTY"
  printf -v "$var_name" '%s' "${value:-$default}"
}

ask_yes_no() {
  local prompt="$1"
  local default="$2"
  local var_name="$3"
  local value=""
  local suffix="[y/N]"

  [[ "$default" == "yes" ]] && suffix="[Y/n]"

  while true; do
    printf '%s %s: ' "$prompt" "$suffix" > "$TTY"
    IFS= read -r value < "$TTY"
    value="${value:-$default}"
    case "${value,,}" in
      y|yes)
        printf -v "$var_name" '%s' "yes"
        return
        ;;
      n|no)
        printf -v "$var_name" '%s' "no"
        return
        ;;
      *)
        say "Answer yes or no."
        ;;
    esac
  done
}

ask_nonnegative_int_default() {
  local prompt="$1"
  local default="$2"
  local var_name="$3"
  local value=""

  while true; do
    printf '%s [%s]: ' "$prompt" "$default" > "$TTY"
    IFS= read -r value < "$TTY"
    value="${value:-$default}"
    if [[ "$value" =~ ^[0-9]+$ ]]; then
      printf -v "$var_name" '%s' "$value"
      return
    fi
    say "Enter 0 or a positive integer."
  done
}

ask_secret_twice() {
  local prompt="$1"
  local var_name="$2"
  local first=""
  local second=""

  while true; do
    printf '%s: ' "$prompt" > "$TTY"
    IFS= read -rs first < "$TTY"
    say ""
    printf 'Confirm %s: ' "$prompt" > "$TTY"
    IFS= read -rs second < "$TTY"
    say ""

    if [[ -z "$first" ]]; then
      say "Secret cannot be empty."
    elif [[ "$first" != "$second" ]]; then
      say "Secrets did not match."
    else
      printf -v "$var_name" '%s' "$first"
      return
    fi
  done
}

validate_hostname() {
  local value="$1"
  [[ "$value" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$ ]]
}

validate_username() {
  local value="$1"
  [[ "$value" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]]
}

validate_timezone() {
  local value="$1"
  [[ -f "/usr/share/zoneinfo/${value}" ]]
}

validate_locale() {
  local value="$1"
  [[ "$value" =~ ^[A-Za-z0-9_.@-]+$ ]]
}

validate_keymap() {
  local value="$1"
  [[ -f "/usr/share/kbd/keymaps/${value}.map.gz" ]] && return 0
  find /usr/share/kbd/keymaps -name "${value}.map.gz" -print -quit | grep -q .
}

normalize_local_dataset_mountpoint() {
  local value="$1"

  value="${value%/}"
  printf '%s\n' "$value"
}

validate_local_dataset_mountpoint() {
  local value="$1"
  local component=""
  local path_without_prefix=""
  local -a components=()

  [[ "$value" == /local/* ]] || return 1
  [[ "$value" != "/local/" ]] || return 1
  [[ "$value" != *"//"* ]] || return 1

  path_without_prefix="${value#/local/}"
  IFS='/' read -ra components <<< "$path_without_prefix"
  for component in "${components[@]}"; do
    [[ -n "$component" ]] || return 1
    [[ "$component" != "." && "$component" != ".." ]] || return 1
    [[ "$component" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || return 1
  done

  return 0
}

collect_additional_local_datasets() {
  local raw=""
  local normalized=""
  local token=""
  local invalid=()
  local seen=""
  local duplicate="no"

  while true; do
    say ""
    say "Optional additional ZFS datasets may be mounted under /local."
    say "Example: /local/development"
    say "Leave blank for none. Separate multiple paths with spaces or commas."
    printf 'Additional /local dataset mountpoints: ' > "$TTY"
    IFS= read -r raw < "$TTY"

    ADDITIONAL_LOCAL_DATASETS=()
    invalid=()

    raw="${raw//,/ }"
    for token in $raw; do
      normalized="$(normalize_local_dataset_mountpoint "$token")"

      if ! validate_local_dataset_mountpoint "$normalized"; then
        invalid+=("$token")
        continue
      fi

      duplicate="no"
      for seen in "${ADDITIONAL_LOCAL_DATASETS[@]}"; do
        if [[ "$seen" == "$normalized" ]]; then
          duplicate="yes"
          break
        fi
      done

      [[ "$duplicate" == "yes" ]] || ADDITIONAL_LOCAL_DATASETS+=("$normalized")
    done

    if ((${#invalid[@]} > 0)); then
      say "Invalid dataset mountpoint(s): ${invalid[*]}"
      say "Use absolute paths below /local with simple path components, for example /local/development or /local/scratch."
      continue
    fi

    if ! validate_no_nested_local_datasets; then
      continue
    fi

    return
  done
}

validate_no_nested_local_datasets() {
  local first=""
  local second=""

  for first in "${ADDITIONAL_LOCAL_DATASETS[@]}"; do
    for second in "${ADDITIONAL_LOCAL_DATASETS[@]}"; do
      [[ "$first" == "$second" ]] && continue
      if [[ "$second" == "${first}/"* ]]; then
        say "Nested additional datasets are not supported in the installer: ${first} contains ${second}"
        say "Choose only one level, for example /local/development, then create deeper directories after install."
        return 1
      fi
    done
  done

  return 0
}

snapshot_policy_name_for_mountpoint() {
  local mountpoint="$1"
  local relative=""
  local name=""

  relative="${mountpoint#/local/}"
  name="${relative}"
  name="${name//_/__}"
  name="${name//-/_h}"
  name="${name//./_p}"
  name="${name//\//_}"
  printf 'local_%s\n' "$name"
}

default_keep_for_class() {
  local class="$1"

  case "$class" in
    10min) printf '%s\n' "20" ;;
    hourly) printf '%s\n' "10" ;;
    daily) printf '%s\n' "7" ;;
    weekly) printf '%s\n' "4" ;;
    monthly) printf '%s\n' "6" ;;
    *) die "Unknown snapshot class: $class" ;;
  esac
}

collect_additional_snapshot_policies() {
  local mountpoint=""
  local separate=""
  local class=""
  local default_keep=""
  local keep=""

  if ((${#ADDITIONAL_LOCAL_DATASETS[@]} == 0)); then
    return
  fi

  say ""
  say "Additional /local datasets can inherit the default snapshot policy or use separate retention."
  say "The default policy is a recursive zroot snapshot. It keeps one coherent snapshot name across root, home, and inherited /local datasets."
  say "If any dataset uses a separate policy, the installer stops using recursive zroot snapshots and creates explicit per-policy dataset snapshots instead."
  say "That materially changes restore semantics in ZFSBootMenu and ZFS. Only choose a separate policy if you are comfortable restoring individual datasets."

  for mountpoint in "${ADDITIONAL_LOCAL_DATASETS[@]}"; do
    ask_yes_no "Use a separate snapshot policy for ${mountpoint}" "no" separate
    ADDITIONAL_LOCAL_SEPARATE_POLICY["$mountpoint"]="$separate"

    if [[ "$separate" == "yes" ]]; then
      SNAPSHOT_USE_RECURSIVE_DEFAULT="no"
      say "Retention for ${mountpoint}. Enter 0 to disable a snapshot class."
      for class in 10min hourly daily weekly monthly; do
        default_keep="$(default_keep_for_class "$class")"
        ask_nonnegative_int_default "Keep ${class} snapshots for ${mountpoint}" "$default_keep" keep
        ADDITIONAL_LOCAL_POLICY_KEEP["${mountpoint}|${class}"]="$keep"
      done
    fi
  done
}

detect_microcode_default() {
  local vendor=""
  vendor="$(awk -F': ' '/vendor_id/ { print $2; exit }' /proc/cpuinfo 2>/dev/null || true)"
  case "$vendor" in
    GenuineIntel) printf '%s\n' "intel-ucode" ;;
    AuthenticAMD) printf '%s\n' "amd-ucode" ;;
    *) printf '%s\n' "none" ;;
  esac
}

list_disks() {
  local path=""
  local size=""
  local model=""
  local serial=""
  local tran=""
  local type=""
  local idx=1

  SELECTABLE_DISKS=()

  say ""
  say "Available whole disks:"

  while IFS=$'\t' read -r path size model serial tran type; do
    [[ -n "$path" ]] || continue
    SELECTABLE_DISKS+=("$path")
    printf '  %d) %-18s %-8s %-24s %-20s %-8s %s\n' \
      "$idx" "$path" "$size" "${model:-unknown}" "${serial:-unknown}" "${tran:-unknown}" "$type" > "$TTY"
    idx=$((idx + 1))
  done < <(lsblk -d -e 7,11 -n -r -o PATH,SIZE,MODEL,SERIAL,TRAN,TYPE | awk 'BEGIN { OFS="\t" } { path=$1; size=$2; type=$NF; tran=$(NF-1); serial=$(NF-2); model=""; for (i=3; i<=NF-3; i++) model=(model ? model " " : "") $i; print path,size,model,serial,tran,type }')

  if ((${#SELECTABLE_DISKS[@]} == 0)); then
    die "No selectable whole disks found."
  fi

  say ""
}

select_target_disks() {
  local raw=""
  local token=""
  local idx=""
  local disk=""
  local stable=""
  local duplicate="no"
  local selected_count=0
  local -a selected=()
  local -a invalid=()

  while true; do
    list_disks
    say "Enter one or two disk numbers separated by commas or spaces, for example: 1,2"
    say "Selected disk count determines the storage topology: one disk is single-disk ZFS; two disks are ZFS mirror plus mdadm ESP."
    printf 'Target disk selection: ' > "$TTY"
    IFS= read -r raw < "$TTY"

    raw="${raw//,/ }"
    selected=()
    invalid=()

    for token in $raw; do
      if [[ ! "$token" =~ ^[0-9]+$ ]]; then
        invalid+=("$token")
        continue
      fi

      idx="$token"
      if ((idx < 1 || idx > ${#SELECTABLE_DISKS[@]})); then
        invalid+=("$token")
        continue
      fi

      disk="${SELECTABLE_DISKS[$((idx - 1))]}"
      validate_disk "$disk" || {
        invalid+=("$token")
        continue
      }

      stable="$(stable_disk_path "$disk")"
      duplicate="no"
      for disk in "${selected[@]}"; do
        if [[ "$disk" == "$stable" ]]; then
          duplicate="yes"
          break
        fi
      done

      if [[ "$duplicate" == "yes" ]]; then
        invalid+=("$token")
        continue
      fi

      selected+=("$stable")
    done

    selected_count="${#selected[@]}"
    if ((${#invalid[@]} > 0)); then
      say "Invalid selection value(s): ${invalid[*]}"
      say "Select one or two unique disk numbers from the list."
      continue
    fi

    if ((selected_count < 1 || selected_count > 2)); then
      say "Select exactly one or two disks."
      continue
    fi

    DISKS=("${selected[@]}")
    DISK_COUNT="$selected_count"
    return
  done
}

stable_disk_path() {
  local disk="$1"
  local real=""
  local candidate=""

  if [[ "$disk" == /dev/disk/by-id/* ]]; then
    printf '%s\n' "$disk"
    return
  fi

  real="$(readlink -f "$disk")"
  while IFS= read -r candidate; do
    if [[ "$(readlink -f "$candidate")" == "$real" ]]; then
      printf '%s\n' "$candidate"
      return
    fi
  done < <(find /dev/disk/by-id -maxdepth 1 -type l ! -name '*-part*' 2>/dev/null | sort)

  printf '%s\n' "$disk"
}

validate_disk() {
  local disk="$1"
  local real=""
  local type=""
  local mounts=""

  if [[ ! -b "$disk" ]]; then
    say "Not a block device: $disk"
    return 1
  fi
  real="$(readlink -f "$disk")"
  type="$(lsblk -dnro TYPE "$real")"
  if [[ "$type" != "disk" ]]; then
    say "Selected target is not a whole disk: $disk"
    return 1
  fi

  mounts="$(lsblk -nrpo MOUNTPOINTS "$real" | awk 'NF' || true)"
  if [[ -n "$mounts" ]]; then
    say "Selected disk has mounted filesystems: $disk"
    return 1
  fi

  return 0
}

collect_inputs() {
  local microcode_default=""

  say "This installer is destructive. It creates an Arch Linux root-on-ZFS system using ZFSBootMenu."
  say "Only continue from the archzfs-lts ISO, after confirming you have backups for any selected disks."

  while true; do
    ask_default "Hostname" "arch-zfs" HOSTNAME
    validate_hostname "$HOSTNAME" && break
    say "Use a valid hostname: letters, numbers, hyphens, not starting or ending with a hyphen."
  done

  while true; do
    ask_default "Timezone" "America/New_York" TIMEZONE
    validate_timezone "$TIMEZONE" && break
    say "Timezone not found under /usr/share/zoneinfo."
  done

  while true; do
    ask_default "Locale" "en_US.UTF-8" LOCALE
    validate_locale "$LOCALE" && break
    say "Use a locale name without spaces or shell metacharacters, for example en_US.UTF-8."
  done

  while true; do
    ask_default "Console keymap" "us" KEYMAP
    validate_keymap "$KEYMAP" && break
    say "Keymap not found under /usr/share/kbd/keymaps."
  done

  microcode_default="$(detect_microcode_default)"
  while true; do
    ask_default "CPU microcode package (intel-ucode, amd-ucode, none)" "$microcode_default" MICROCODE
    case "$MICROCODE" in
      intel-ucode|amd-ucode|none) break ;;
      *) say "Choose intel-ucode, amd-ucode, or none." ;;
    esac
  done

  ask_yes_no "Install OpenSSH server" "no" INSTALL_SSH
  collect_additional_local_datasets
  collect_additional_snapshot_policies

  select_target_disks

  ask_secret_twice "Root password" ROOT_PASSWORD
  ask_secret_twice "ZFS encryption passphrase" ZFS_PASSPHRASE

  ask_yes_no "Create a non-root user account" "no" CREATE_USER
  if [[ "$CREATE_USER" == "yes" ]]; then
    while true; do
      ask_required "Username" NEW_USERNAME
      validate_username "$NEW_USERNAME" && break
      say "Use a valid Linux username: lowercase letter or underscore first, then lowercase letters, digits, underscore, or hyphen."
    done
    ask_secret_twice "Password for ${NEW_USERNAME}" NEW_USER_PASSWORD
    ask_yes_no "Allow ${NEW_USERNAME} to use sudo" "no" NEW_USER_SUDO
  fi
}

confirm_destruction() {
  local confirmation=""

  say ""
  say "DESTRUCTIVE INSTALL SUMMARY"
  say "Hostname: ${HOSTNAME}"
  say "Timezone: ${TIMEZONE}"
  say "Locale: ${LOCALE}"
  say "Keymap: ${KEYMAP}"
  say "Microcode package: ${MICROCODE}"
  say "OpenSSH: ${INSTALL_SSH}"
  if ((${#ADDITIONAL_LOCAL_DATASETS[@]} > 0)); then
    say "Additional /local datasets:"
    local mountpoint=""
    local class=""
    local keep=""
    for mountpoint in "${ADDITIONAL_LOCAL_DATASETS[@]}"; do
      if [[ "${ADDITIONAL_LOCAL_SEPARATE_POLICY[$mountpoint]}" == "yes" ]]; then
        say "  - ${mountpoint} (separate snapshot policy)"
        for class in 10min hourly daily weekly monthly; do
          keep="${ADDITIONAL_LOCAL_POLICY_KEEP["${mountpoint}|${class}"]}"
          say "      ${class}: keep ${keep}"
        done
      else
        say "  - ${mountpoint} (default snapshot policy)"
      fi
    done
  else
    say "Additional /local datasets: none"
  fi
  if [[ "$SNAPSHOT_USE_RECURSIVE_DEFAULT" == "yes" ]]; then
    say "Default snapshot model: recursive zroot snapshots"
  else
    say "Default snapshot model: explicit dataset list because at least one /local dataset has separate retention"
  fi
  say "Create user: ${CREATE_USER}"
  if [[ "$CREATE_USER" == "yes" ]]; then
    say "New user: ${NEW_USERNAME}; sudo: ${NEW_USER_SUDO}"
  fi
  say "Target disks:"
  printf '  - %s\n' "${DISKS[@]}" > "$TTY"
  if ((DISK_COUNT == 1)); then
    say "Storage topology: single-disk encrypted ZFS pool, standalone ESP, random encrypted swap."
  else
    say "Storage topology: encrypted ZFS mirror, mdadm RAID1 ESP, random encrypted swap on both disks."
  fi
  say ""
  say "ALL DATA ON THE TARGET DISK(S) ABOVE WILL BE DESTROYED."
  say "Type WIPE to continue. Anything else aborts."
  printf 'Confirmation: ' > "$TTY"
  IFS= read -r confirmation < "$TTY"
  [[ "$confirmation" == "WIPE" ]] || die "Aborted before destructive actions."
}

hash_passwords() {
  ROOT_HASH="$(printf '%s' "$ROOT_PASSWORD" | openssl passwd -6 -stdin)"
  unset ROOT_PASSWORD

  if [[ "$CREATE_USER" == "yes" ]]; then
    NEW_USER_HASH="$(printf '%s' "$NEW_USER_PASSWORD" | openssl passwd -6 -stdin)"
    unset NEW_USER_PASSWORD
  fi
}

prepare_secret_files() {
  install -d -m 0700 "$INSTALL_RUN_DIR"
  install -m 0600 /dev/null "$ZFS_KEYFILE"
  printf '%s' "$ZFS_PASSPHRASE" > "$ZFS_KEYFILE"
  chmod 0400 "$ZFS_KEYFILE"
  unset ZFS_PASSPHRASE
}

stop_existing_arrays() {
  mdadm --stop /dev/md/esp >/dev/null 2>&1 || true
}

wipe_disk() {
  local disk="$1"
  local child=""

  say "Wiping signatures and partition table on $disk"
  while IFS= read -r child; do
    swapoff "$child" >/dev/null 2>&1 || true
    mdadm --zero-superblock --force "$child" >/dev/null 2>&1 || true
    zpool labelclear -f "$child" >/dev/null 2>&1 || true
    wipefs -af "$child" >/dev/null 2>&1 || true
  done < <(lsblk -nrpo PATH "$disk" | tac)

  sgdisk --zap-all "$disk"
  wipefs -af "$disk"
}

partition_disk() {
  local disk="$1"

  say "Creating GPT layout on $disk"
  sgdisk \
    --new=1:1MiB:+512MiB --typecode=1:ef00 --change-name=1:EFI \
    --new=2:0:+4GiB      --typecode=2:8309 --change-name=2:cryptswap \
    --new=3:0:0          --typecode=3:bf00 --change-name=3:zfsroot \
    "$disk"
}

partition_path() {
  local disk="$1"
  local number="$2"
  local candidate=""
  local real_disk=""
  local child=""
  local partnum=""

  if [[ "$disk" == /dev/disk/by-id/* || "$disk" == /dev/disk/by-path/* ]]; then
    candidate="${disk}-part${number}"
  elif [[ "$disk" =~ [0-9]$ ]]; then
    candidate="${disk}p${number}"
  else
    candidate="${disk}${number}"
  fi

  if [[ -b "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return
  fi

  real_disk="$(readlink -f "$disk")"
  while IFS= read -r child; do
    partnum="$(lsblk -nro PARTN "$child" 2>/dev/null || true)"
    if [[ "$partnum" == "$number" ]]; then
      printf '%s\n' "$child"
      return
    fi
  done < <(lsblk -nrpo PATH "$real_disk" | tail -n +2)

  die "Could not find partition ${number} for ${disk}"
}

stable_partition_path() {
  local part="$1"
  local real=""
  local candidate=""

  if [[ "$part" == /dev/disk/by-id/* ]]; then
    printf '%s\n' "$part"
    return
  fi

  real="$(readlink -f "$part")"
  while IFS= read -r candidate; do
    if [[ "$(readlink -f "$candidate")" == "$real" ]]; then
      printf '%s\n' "$candidate"
      return
    fi
  done < <(find /dev/disk/by-id -maxdepth 1 -type l -name '*-part*' 2>/dev/null | sort)

  printf '%s\n' "$part"
}

prepare_partitions() {
  local disk=""
  local esp=""
  local swap=""
  local zfs_part=""

  stop_existing_arrays

  for disk in "${DISKS[@]}"; do
    wipe_disk "$disk"
  done

  for disk in "${DISKS[@]}"; do
    partition_disk "$disk"
  done

  for disk in "${DISKS[@]}"; do
    partprobe "$disk"
  done
  udevadm settle
  sleep 2

  ESP_PARTS=()
  SWAP_PARTS=()
  ZFS_PARTS=()

  for disk in "${DISKS[@]}"; do
    esp="$(stable_partition_path "$(partition_path "$disk" 1)")"
    swap="$(stable_partition_path "$(partition_path "$disk" 2)")"
    zfs_part="$(stable_partition_path "$(partition_path "$disk" 3)")"
    ESP_PARTS+=("$esp")
    SWAP_PARTS+=("$swap")
    ZFS_PARTS+=("$zfs_part")
  done
}

create_efi() {
  if ((DISK_COUNT == 1)); then
    EFI_DEVICE="${ESP_PARTS[0]}"
    mkfs.vfat -F 32 -n EFI "$EFI_DEVICE"
    return
  fi

  say "Creating mdadm RAID1 ESP with metadata 1.0"
  mkdir -p /dev/md
  mdadm --create --verbose --run --level=1 --metadata=1.0 \
    --homehost=any --raid-devices=2 /dev/md/esp \
    --bitmap=internal "${ESP_PARTS[@]}"

  mdadm --detail --scan > /etc/mdadm.conf
cat >> /etc/mdadm.conf <<'EOF'
POLICY metadata=1.x path=/dev/disk/by-path/* type=part action=re-add auto=yes
MAILADDR root
EOF

  mdadm --udev-rules=/etc/udev/rules.d/65-md-bare.rules
  cat > /etc/udev/rules.d/69-md-incremental-run.rules <<'EOF'
ACTION=="add|change", SUBSYSTEM=="block", ENV{DEVTYPE}=="partition", IMPORT{program}="/usr/bin/mdadm --incremental --run --export $devnode --offroot $env{DEVLINKS}"
EOF

  udevadm control --reload
  udevadm trigger
  udevadm settle

  EFI_DEVICE=/dev/md/esp
  mkfs.vfat -F 32 -n EFI "$EFI_DEVICE"
}

create_zpool() {
  local -a vdev_args=()
  local pool_guid=""
  local mountpoint=""
  local relative_dataset=""

  say "Generating hostid"
  rm -f /etc/hostid
  zgenhostid

  if ((DISK_COUNT == 1)); then
    vdev_args=("${ZFS_PARTS[0]}")
  else
    vdev_args=(mirror "${ZFS_PARTS[@]}")
  fi

  say "Creating encrypted ZFS pool ${POOL}"
  zpool create -f -o ashift=12 \
    -O compression=lz4 \
    -O acltype=posixacl \
    -O xattr=sa \
    -O relatime=on \
    -O encryption=aes-256-gcm \
    -O keylocation="file://${ZFS_KEYFILE}" \
    -O keyformat=passphrase \
    -o autotrim=on \
    -o autoreplace=on \
    -m none "$POOL" "${vdev_args[@]}"

  zfs create -o mountpoint=none "${POOL}/ROOT"
  zfs create -o mountpoint=/ -o canmount=noauto "${POOL}/ROOT/arch"
  zfs create -o mountpoint=/home "${POOL}/home"
  if ((${#ADDITIONAL_LOCAL_DATASETS[@]} > 0)); then
    zfs create -o mountpoint=/local "${POOL}/local"
    for mountpoint in "${ADDITIONAL_LOCAL_DATASETS[@]}"; do
      relative_dataset="${mountpoint#/local/}"
      if ! zfs list -H "${POOL}/local/${relative_dataset}" >/dev/null 2>&1; then
        zfs create -p "${POOL}/local/${relative_dataset}"
      fi
    done
  fi

  pool_guid="$(zpool get -H -o value guid "$POOL")"
  zpool export "$POOL"
  zpool import -N -R "$TARGET" "$pool_guid"
  zfs load-key -L "file://${ZFS_KEYFILE}" "$POOL"
  zfs mount "${POOL}/ROOT/arch"
  zfs mount -a
  zfs set keylocation=prompt "$POOL"
  zfs set snapdir=visible "${POOL}/home"
  udevadm trigger
}

pacstrap_target() {
  local -a packages=(
    base
    linux-lts
    linux-firmware
    linux-lts-headers
    zfs-dkms
    curl
    vim
    networkmanager
    dhcpcd
  )

  if ((DISK_COUNT == 2)); then
    packages+=(mdadm)
  fi

  if [[ "$MICROCODE" != "none" ]]; then
    packages+=("$MICROCODE")
  fi

  if [[ "$INSTALL_SSH" == "yes" ]]; then
    packages+=(openssh)
  fi

  if [[ "$CREATE_USER" == "yes" && "$NEW_USER_SUDO" == "yes" ]]; then
    packages+=(sudo)
  fi

  say "Installing base system packages"
  pacstrap "$TARGET" "${packages[@]}"
  assert_target_core_directory_modes
}

assert_target_core_directory_modes() {
  local path=""
  local mode=""

  for path in "$TARGET" "$TARGET/etc" "$TARGET/var" "$TARGET/var/lib"; do
    mode="$(stat -c '%a' "$path")"
    if [[ "$mode" != "755" ]]; then
      die "${path} has mode ${mode}, expected 755. Stop here; package installation created an invalid base filesystem."
    fi
  done
}

configure_basic_files() {
  local locale_base="${LOCALE%%.*}"
  local locale_charset="${LOCALE#*.}"
  local locale_gen_line=""

  if [[ "$locale_charset" == "$LOCALE" || -z "$locale_charset" ]]; then
    locale_charset="UTF-8"
  fi
  locale_gen_line="${locale_base}.${locale_charset} ${locale_charset}"

  cp /etc/hostid "$TARGET/etc/hostid"
  cp /etc/resolv.conf "$TARGET/etc/resolv.conf"
  cp /etc/pacman.conf "$TARGET/etc/pacman.conf"

  if ((DISK_COUNT == 2)); then
    cp /etc/mdadm.conf "$TARGET/etc/mdadm.conf"
    mkdir -p "$TARGET/etc/udev/rules.d"
    cp -a /etc/udev/rules.d/. "$TARGET/etc/udev/rules.d/"
  fi

  mkdir -p "$TARGET/efi"
  mount "$EFI_DEVICE" "$TARGET/efi"

  genfstab -U "$TARGET" > "$TARGET/etc/fstab.generated"
  awk '$3 != "zfs" { print }' "$TARGET/etc/fstab.generated" > "$TARGET/etc/fstab"
  rm -f "$TARGET/etc/fstab.generated"

  {
    printf '%s\n' "$HOSTNAME"
  } > "$TARGET/etc/hostname"

  cat > "$TARGET/etc/hosts" <<EOF
127.0.0.1 localhost
::1 localhost
127.0.1.1 ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

  sed -i "s/^#${locale_gen_line}/${locale_gen_line}/" "$TARGET/etc/locale.gen"
  if ! grep -Fxq "$locale_gen_line" "$TARGET/etc/locale.gen"; then
    printf '%s\n' "$locale_gen_line" >> "$TARGET/etc/locale.gen"
  fi

  cat > "$TARGET/etc/locale.conf" <<EOF
LANG=${LOCALE}
EOF

  cat > "$TARGET/etc/vconsole.conf" <<EOF
KEYMAP=${KEYMAP}
EOF
}

configure_swap() {
  local idx=1
  local part=""
  local partuuid=""

  : > "$TARGET/etc/crypttab"
  for part in "${SWAP_PARTS[@]}"; do
    partuuid="$(blkid -s PARTUUID -o value "$part")"
    [[ -n "$partuuid" ]] || die "Could not determine PARTUUID for swap partition $part"
    printf 'cryptswap%s PARTUUID=%s /dev/urandom swap,cipher=aes-xts-plain64,size=256\n' "$idx" "$partuuid" >> "$TARGET/etc/crypttab"
    printf '/dev/mapper/cryptswap%s none swap defaults,pri=100 0 0\n' "$idx" >> "$TARGET/etc/fstab"
    idx=$((idx + 1))
  done
}

configure_mkinitcpio() {
  local hooks="base udev autodetect microcode modconf keyboard keymap block zfs filesystems"

  if ((DISK_COUNT == 2)); then
    hooks="base udev autodetect microcode modconf keyboard keymap block mdadm_udev zfs filesystems"
  fi

  sed -i \
    -e 's|^FILES=.*|FILES=(/etc/hostid /etc/zfs/zpool.cache)|' \
    -e "s|^HOOKS=.*|HOOKS=(${hooks})|" \
    "$TARGET/etc/mkinitcpio.conf"
}

write_autosnapshot_config() {
  local config="$TARGET/etc/zfs/arch-autosnapshot.conf"
  local mountpoint=""
  local relative_dataset=""
  local policy=""
  local class=""
  local keep=""

  {
    printf 'POOL=zroot\n'
    printf 'CAPACITY_WARN=80\n'
    printf 'CAPACITY_CRITICAL=90\n'
    printf 'RECURSIVE_DEFAULT=%q\n' "$SNAPSHOT_USE_RECURSIVE_DEFAULT"
    printf 'declare -A SNAPSHOT_POLICY_DATASETS=(\n'
    printf '  ["default"]="zroot/ROOT:r zroot/home:r'

    if ((${#ADDITIONAL_LOCAL_DATASETS[@]} > 0)); then
      printf ' zroot/local:n'
      for mountpoint in "${ADDITIONAL_LOCAL_DATASETS[@]}"; do
        if [[ "${ADDITIONAL_LOCAL_SEPARATE_POLICY[$mountpoint]}" != "yes" ]]; then
          relative_dataset="${mountpoint#/local/}"
          printf ' zroot/local/%s:r' "$relative_dataset"
        fi
      done
    fi

    printf '"\n'
    for mountpoint in "${ADDITIONAL_LOCAL_DATASETS[@]}"; do
      if [[ "${ADDITIONAL_LOCAL_SEPARATE_POLICY[$mountpoint]}" == "yes" ]]; then
        policy="$(snapshot_policy_name_for_mountpoint "$mountpoint")"
        relative_dataset="${mountpoint#/local/}"
        printf '  ["%s"]="zroot/local/%s:r"\n' "$policy" "$relative_dataset"
      fi
    done
    printf ')\n'

    printf 'declare -A SNAPSHOT_POLICY_KEEP=(\n'
    for class in 10min hourly daily weekly monthly; do
      keep="$(default_keep_for_class "$class")"
      printf '  ["default|%s"]=%s\n' "$class" "$keep"
    done

    for mountpoint in "${ADDITIONAL_LOCAL_DATASETS[@]}"; do
      if [[ "${ADDITIONAL_LOCAL_SEPARATE_POLICY[$mountpoint]}" == "yes" ]]; then
        policy="$(snapshot_policy_name_for_mountpoint "$mountpoint")"
        for class in 10min hourly daily weekly monthly; do
          keep="${ADDITIONAL_LOCAL_POLICY_KEEP["${mountpoint}|${class}"]}"
          printf '  ["%s|%s"]=%s\n' "$policy" "$class" "$keep"
        done
      fi
    done
    printf ')\n'
  } > "$config"
}

write_autosnapshot_timer() {
  local policy="$1"
  local class="$2"
  local unit="zfs-autosnapshot@${policy}--${class}.service"
  local timer="zfs-autosnapshot-${policy}--${class}.timer"
  local path="$TARGET/etc/systemd/system/${timer}"

  case "$class" in
    10min)
      cat > "$path" <<EOF
[Unit]
Description=Create ${policy} ZFS snapshots every 10 minutes

[Timer]
OnBootSec=10min
OnUnitActiveSec=10min
AccuracySec=1min
Unit=${unit}

[Install]
WantedBy=timers.target
EOF
      ;;
    hourly)
      cat > "$path" <<EOF
[Unit]
Description=Create hourly ${policy} ZFS snapshots

[Timer]
OnCalendar=hourly
Persistent=true
AccuracySec=5min
Unit=${unit}

[Install]
WantedBy=timers.target
EOF
      ;;
    daily)
      cat > "$path" <<EOF
[Unit]
Description=Create daily ${policy} ZFS snapshots

[Timer]
OnCalendar=daily
Persistent=true
AccuracySec=30min
Unit=${unit}

[Install]
WantedBy=timers.target
EOF
      ;;
    weekly)
      cat > "$path" <<EOF
[Unit]
Description=Create weekly ${policy} ZFS snapshots

[Timer]
OnCalendar=weekly
Persistent=true
AccuracySec=1h
Unit=${unit}

[Install]
WantedBy=timers.target
EOF
      ;;
    monthly)
      cat > "$path" <<EOF
[Unit]
Description=Create monthly ${policy} ZFS snapshots

[Timer]
OnCalendar=monthly
Persistent=true
AccuracySec=6h
Unit=${unit}

[Install]
WantedBy=timers.target
EOF
      ;;
    *)
      die "Unknown snapshot class: $class"
      ;;
  esac

  SNAPSHOT_TIMER_UNITS+=("$timer")
}

write_autosnapshot_timers() {
  local policy=""
  local mountpoint=""
  local class=""
  local keep=""

  SNAPSHOT_TIMER_UNITS=()

  for class in 10min hourly daily weekly monthly; do
    write_autosnapshot_timer "default" "$class"
  done

  for mountpoint in "${ADDITIONAL_LOCAL_DATASETS[@]}"; do
    if [[ "${ADDITIONAL_LOCAL_SEPARATE_POLICY[$mountpoint]}" != "yes" ]]; then
      continue
    fi

    policy="$(snapshot_policy_name_for_mountpoint "$mountpoint")"
    for class in 10min hourly daily weekly monthly; do
      keep="${ADDITIONAL_LOCAL_POLICY_KEEP["${mountpoint}|${class}"]}"
      if ((keep > 0)); then
        write_autosnapshot_timer "$policy" "$class"
      fi
    done
  done
}

install_zfs_maintenance() {
  mkdir -p "$TARGET/etc/zfs" "$TARGET/usr/local/sbin" "$TARGET/etc/systemd/system"

  write_autosnapshot_config

  cat > "$TARGET/usr/local/sbin/zfs-autosnapshot" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

CONFIG=/etc/zfs/arch-autosnapshot.conf
if [[ -r "$CONFIG" ]]; then
  # shellcheck source=/dev/null
  . "$CONFIG"
fi

POOL="${POOL:-zroot}"
CAPACITY_WARN="${CAPACITY_WARN:-80}"
CAPACITY_CRITICAL="${CAPACITY_CRITICAL:-90}"
RECURSIVE_DEFAULT="${RECURSIVE_DEFAULT:-no}"
INSTANCE="${1:?snapshot policy and class required}"

CLASS="${INSTANCE##*--}"
POLICY="${INSTANCE%--${CLASS}}"
KEEP="${SNAPSHOT_POLICY_KEEP["${POLICY}|${CLASS}"]:-}"
DATASET_SPECS="${SNAPSHOT_POLICY_DATASETS["${POLICY}"]:-}"

if [[ -z "$KEEP" || -z "$DATASET_SPECS" || "$POLICY" == "$INSTANCE" ]]; then
  echo "Unknown snapshot policy/class: ${INSTANCE}" >&2
  exit 64
fi

if ((KEEP <= 0)); then
  exit 0
fi

capacity="$(zpool list -H -o capacity "$POOL" | tr -d '%')"
if [[ "$capacity" =~ ^[0-9]+$ ]]; then
  if ((capacity >= CAPACITY_CRITICAL)); then
    logger -p daemon.err -t zfs-autosnapshot "pool ${POOL} is ${capacity}% full; creating ${POLICY}/${CLASS} snapshot but capacity is critical"
  elif ((capacity >= CAPACITY_WARN)); then
    logger -p daemon.warning -t zfs-autosnapshot "pool ${POOL} is ${capacity}% full"
  fi
fi

snapshot_name="autosnap_${POLICY}_${CLASS}_$(date -u +%Y%m%dT%H%M%SZ)"

if [[ "$POLICY" == "default" && "$RECURSIVE_DEFAULT" == "yes" ]]; then
  zfs snapshot -r "${POOL}@${snapshot_name}"
  mapfile -t snapshots < <(zfs list -H -t snapshot -o name -s creation -d 1 "$POOL" | grep -F "${POOL}@autosnap_${POLICY}_${CLASS}_" || true)
  excess=$((${#snapshots[@]} - KEEP))
  if ((excess > 0)); then
    for ((i = 0; i < excess; i++)); do
      zfs destroy -r "${snapshots[$i]}"
    done
  fi
  exit 0
fi

for spec in $DATASET_SPECS; do
  dataset="${spec%:*}"
  mode="${spec##*:}"

  case "$mode" in
    r) zfs snapshot -r "${dataset}@${snapshot_name}" ;;
    n) zfs snapshot "${dataset}@${snapshot_name}" ;;
    *) echo "Unknown snapshot mode for ${spec}" >&2; exit 65 ;;
  esac
done

for spec in $DATASET_SPECS; do
  dataset="${spec%:*}"
  mode="${spec##*:}"
  mapfile -t snapshots < <(zfs list -H -t snapshot -o name -s creation -d 1 "$dataset" | grep -F "${dataset}@autosnap_${POLICY}_${CLASS}_" || true)
  excess=$((${#snapshots[@]} - KEEP))
  if ((excess > 0)); then
    for ((i = 0; i < excess; i++)); do
      case "$mode" in
        r) zfs destroy -r "${snapshots[$i]}" ;;
        n) zfs destroy "${snapshots[$i]}" ;;
        *) echo "Unknown snapshot mode for ${spec}" >&2; exit 65 ;;
      esac
    done
  fi
done
EOF
  chmod 0755 "$TARGET/usr/local/sbin/zfs-autosnapshot"

  cat > "$TARGET/usr/local/sbin/zfs-health-check" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

CONFIG=/etc/zfs/arch-autosnapshot.conf
if [[ -r "$CONFIG" ]]; then
  # shellcheck source=/dev/null
  . "$CONFIG"
fi

POOL="${POOL:-zroot}"
CAPACITY_WARN="${CAPACITY_WARN:-80}"
CAPACITY_CRITICAL="${CAPACITY_CRITICAL:-90}"
status="0"

health="$(zpool get -H -o value health "$POOL")"
if [[ "$health" != "ONLINE" ]]; then
  logger -p daemon.err -t zfs-health-check "pool ${POOL} health is ${health}"
  zpool status "$POOL"
  status="1"
fi

capacity="$(zpool list -H -o capacity "$POOL" | tr -d '%')"
if [[ "$capacity" =~ ^[0-9]+$ ]]; then
  if ((capacity >= CAPACITY_CRITICAL)); then
    logger -p daemon.err -t zfs-health-check "pool ${POOL} capacity is critical: ${capacity}%"
    status="1"
  elif ((capacity >= CAPACITY_WARN)); then
    logger -p daemon.warning -t zfs-health-check "pool ${POOL} capacity warning: ${capacity}%"
  fi
fi

zpool status -x "$POOL"
exit "$status"
EOF
  chmod 0755 "$TARGET/usr/local/sbin/zfs-health-check"

  cat > "$TARGET/etc/systemd/system/zfs-autosnapshot@.service" <<'EOF'
[Unit]
Description=Create and prune ZFS %i snapshots
After=zfs-mount.service
Requires=zfs-mount.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/zfs-autosnapshot %i
EOF

  write_autosnapshot_timers

  cat > "$TARGET/etc/systemd/system/zfs-scrub@.service" <<'EOF'
[Unit]
Description=Scrub ZFS pool %i
After=zfs-import.target
Requires=zfs-import.target

[Service]
Type=oneshot
ExecStart=/usr/bin/zpool scrub %i
EOF

  cat > "$TARGET/etc/systemd/system/zfs-scrub@.timer" <<'EOF'
[Unit]
Description=Weekly scrub for ZFS pool %i

[Timer]
OnCalendar=Sun *-*-* 03:30
Persistent=true
AccuracySec=1h

[Install]
WantedBy=timers.target
EOF

  cat > "$TARGET/etc/systemd/system/zfs-health-check.service" <<'EOF'
[Unit]
Description=Check ZFS pool health and capacity
After=zfs-import.target
Requires=zfs-import.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/zfs-health-check
EOF

  cat > "$TARGET/etc/systemd/system/zfs-health-check.timer" <<'EOF'
[Unit]
Description=Daily ZFS pool health and capacity check

[Timer]
OnCalendar=daily
Persistent=true
AccuracySec=30min

[Install]
WantedBy=timers.target
EOF
}

configure_no_hibernation() {
  mkdir -p "$TARGET/etc/systemd/sleep.conf.d"
  cat > "$TARGET/etc/systemd/sleep.conf.d/10-zfs-no-hibernate.conf" <<'EOF'
[Sleep]
AllowHibernation=no
AllowSuspendThenHibernate=no
AllowHybridSleep=no
EOF
}

configure_zed() {
  mkdir -p "$TARGET/etc/zfs/zed.d"
  cat > "$TARGET/etc/zfs/zed.d/all-pool-state-log.sh" <<'EOF'
#!/usr/bin/env bash
set -u

case "${ZEVENT_SUBCLASS:-}" in
  statechange|config_sync|resilver_start|resilver_finish|scrub_start|scrub_finish|scrub_abort|scrub_resume|scrub_paused|vdev_add|vdev_attach|vdev_remove|vdev_remove_dev|vdev_online|vdev_clear|probe_failure|io|checksum|data|deadman|delay|vdev.open_failed|vdev.no_replicas|vdev.unknown|vdev.bad_guid_sum|pool_import|pool_export|pool_create|pool_destroy)
    ;;
  *)
    exit 0
    ;;
esac

POOL="${ZEVENT_POOL:-unknown}"

{
  printf 'time=%s eid=%s class=%s subclass=%s pool=%s vdev_path=%s vdev_state=%s prev_state=%s\n' \
    "${ZEVENT_TIME_STRING:-}" \
    "${ZEVENT_EID:-}" \
    "${ZEVENT_CLASS:-}" \
    "${ZEVENT_SUBCLASS:-}" \
    "$POOL" \
    "${ZEVENT_VDEV_PATH:-}" \
    "${ZEVENT_VDEV_STATE:-}" \
    "${ZEVENT_PREV_STATE:-}"
  "${ZPOOL:-/usr/bin/zpool}" status "$POOL" 2>&1
  printf '\n'
} | systemd-cat -t zfs-zed-pool-state -p info
EOF
  chmod 0700 "$TARGET/etc/zfs/zed.d/all-pool-state-log.sh"
}

run_chroot_configuration() {
  local enable_units=(
    NetworkManager.service
    zfs-zed.service
    zfs.target
    zfs-import.target
    zfs-import-cache.service
    zfs-mount.service
    zfs-scrub@zroot.timer
    zfs-health-check.timer
  )

  enable_units+=("${SNAPSHOT_TIMER_UNITS[@]}")

  if [[ "$INSTALL_SSH" == "yes" ]]; then
    enable_units+=(sshd.service)
  fi

  say "Configuring installed system"
  arch-chroot "$TARGET" ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
  arch-chroot "$TARGET" hwclock --systohc
  arch-chroot "$TARGET" locale-gen

  printf 'root:%s\n' "$ROOT_HASH" | arch-chroot "$TARGET" chpasswd -e
  unset ROOT_HASH

  if [[ "$CREATE_USER" == "yes" ]]; then
    arch-chroot "$TARGET" useradd -m -G wheel -s /bin/bash "$NEW_USERNAME"
    printf '%s:%s\n' "$NEW_USERNAME" "$NEW_USER_HASH" | arch-chroot "$TARGET" chpasswd -e
    unset NEW_USER_HASH

    if [[ "$NEW_USER_SUDO" == "yes" ]]; then
      cat > "$TARGET/etc/sudoers.d/10-wheel" <<'EOF'
%wheel ALL=(ALL:ALL) ALL
EOF
      chmod 0440 "$TARGET/etc/sudoers.d/10-wheel"
      arch-chroot "$TARGET" visudo -cf /etc/sudoers
    fi
  fi

  arch-chroot "$TARGET" zpool set cachefile=/etc/zfs/zpool.cache "$POOL"
  arch-chroot "$TARGET" zpool set bootfs="${POOL}/ROOT/arch" "$POOL"
  arch-chroot "$TARGET" zfs set org.zfsbootmenu:commandline="noresume init_on_alloc=0 rw" "${POOL}/ROOT"

  arch-chroot "$TARGET" mkinitcpio -P
  arch-chroot "$TARGET" lsinitcpio -l /boot/initramfs-linux-lts.img | grep -q '^etc/hostid$' || die "/etc/hostid missing from initramfs"
  arch-chroot "$TARGET" lsinitcpio -l /boot/initramfs-linux-lts.img | grep -q '^etc/zfs/zpool.cache$' || die "/etc/zfs/zpool.cache missing from initramfs"

  arch-chroot "$TARGET" systemctl mask hibernate.target hybrid-sleep.target suspend-then-hibernate.target
  arch-chroot "$TARGET" systemctl enable "${enable_units[@]}"
}

install_zfsbootmenu() {
  say "Installing ZFSBootMenu EFI artifacts"
  arch-chroot "$TARGET" mkdir -p /efi/EFI/zbm /efi/EFI/BOOT

  curl_retry https://get.zfsbootmenu.org/efi "$TARGET/efi/EFI/zbm/zfsbootmenu.EFI"
  curl_retry https://get.zfsbootmenu.org/zbm-kcl "$TARGET/usr/local/bin/zbm-kcl"
  arch-chroot "$TARGET" chmod 0755 /usr/local/bin/zbm-kcl
  arch-chroot "$TARGET" cp /efi/EFI/zbm/zfsbootmenu.EFI /efi/EFI/BOOT/BOOTX64.EFI
  curl_retry https://get.zfsbootmenu.org/efi/recovery "$TARGET/root/zfsbootmenu.recovery.EFI"

  arch-chroot "$TARGET" zbm-kcl \
    -a "spl_hostid=0x$(hostid)" \
    -a 'zbm.prefer=zroot!!' \
    -a 'zbm.import_policy=hostid' \
    -a 'zbm.set_hostid=1' \
    -a 'zbm.timeout=10' \
    /efi/EFI/zbm/zfsbootmenu.EFI

  arch-chroot "$TARGET" cp /efi/EFI/zbm/zfsbootmenu.EFI /efi/EFI/BOOT/BOOTX64.EFI

  arch-chroot "$TARGET" zbm-kcl \
    -a "spl_hostid=0x$(hostid)" \
    -a 'zbm.prefer=zroot!!' \
    -a 'zbm.import_policy=force' \
    -a 'zbm.set_hostid=1' \
    -a 'zbm.timeout=-1' \
    /root/zfsbootmenu.recovery.EFI
}

finalize_install() {
  say "Final validation"
  zpool status -P "$POOL"
  if ((DISK_COUNT == 2)); then
    cat /proc/mdstat
    mdadm --detail /dev/md/esp
  fi

  sync
  umount "$TARGET/efi"
  zfs unmount -a
  zpool export "$POOL"

  say ""
  say "Install complete. Remove the install media and reboot."
}

main() {
  require_tty
  require_root
  require_uefi
  collect_inputs
  confirm_destruction
  require_arch_iso_tools
  require_clean_target
  hash_passwords
  prepare_secret_files
  prepare_partitions
  create_efi
  create_zpool
  pacstrap_target
  configure_basic_files
  configure_swap
  configure_mkinitcpio
  install_zfs_maintenance
  configure_no_hibernation
  configure_zed
  run_chroot_configuration
  install_zfsbootmenu
  finalize_install
}

main "$@"
