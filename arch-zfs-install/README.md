# Arch ZFS Install

This directory contains an opinionated Arch Linux installer for my root-on-ZFS systems.

The goal is a repeatable base install that supports local point-in-time recovery, file-level recovery, and a clean path toward disaster recovery. If a system is stolen, destroyed, or otherwise unavailable, the base system should be reproducible quickly and ready for later restore layers.

This is not a general-purpose Arch installer. It encodes the storage, boot, snapshot, and safety choices I want for my own machines.

## What It Builds

The installer starts from an `archzfs-lts` ISO and creates:

* UEFI-only Arch Linux install
* `linux-lts` root-on-ZFS system
* ZFS native encryption
* ZFSBootMenu boot flow
* single-disk ZFS install when one disk is selected
* mirrored ZFS root when two disks are selected
* mdadm RAID1 EFI system partition for two-disk installs
* random encrypted swap outside ZFS
* optional non-root user
* optional sudo setup
* optional OpenSSH server
* local ZFS snapshots using systemd timers
* root-only pre-upgrade ZFS snapshots using a pacman ALPM hook
* encrypted, snapshot-excluded Docker/containerd datasets with a 40 GiB combined quota
* weekly scrub and daily pool health checks
* hibernation disabled for root-on-ZFS safety

Desktop environment setup, dotfiles, replication, restic, and user-level customization are intentionally out of scope.

## Usage

Boot the target machine from the [archzfs-lts ISO](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs), then run:

```bash
curl http://<host>:<port>/install-arch-zfs.sh | bash
```

The script prompts for all required choices up front, including:

* hostname
* timezone
* locale
* keymap
* CPU microcode package
* optional SSH
* optional `/local` datasets
* target disks
* root password
* ZFS encryption passphrase
* optional non-root account

Disk selection is destructive. The script lists available disks, asks for one or two disk numbers, and requires an explicit `WIPE` confirmation before changing disks.

## Snapshot Policy

By default, snapshots target explicit datasets without recursion. The root boot environment, home, and inherited `/local` datasets receive independent snapshots under the same retention schedule. Child datasets used for volatile storage are not pulled into root snapshots.

The default schedule keeps 4 ten-minute snapshots, 4 hourly snapshots, 3 daily snapshots, 2 weekly snapshots, and 2 monthly snapshots per included dataset.

Optional `/local` datasets can be given separate retention policies. Root snapshots remain directly usable by ZFSBootMenu; home and `/local` snapshots provide independent file-level recovery.

Package upgrades create a snapshot of `zroot/ROOT/arch` before the transaction starts. The installer writes `/usr/local/sbin/zfs-prepacman-snapshot` and `/etc/pacman.d/hooks/zfs-snapshot-pre.hook`; the hook is a `PreTransaction` ALPM hook for package `Upgrade` operations. Snapshot names use the same timestamp style as the timer snapshots, for example:

```bash
zroot/ROOT/arch@pre_update_20260419T143000Z
```

The pre-upgrade hook keeps the newest 3 `pre_update_*` root snapshots by count. It uses `AbortOnFail`, so pacman will stop before changing packages if the safety snapshot cannot be created. If an old snapshot cannot be pruned after the new one is created, the hook logs a warning and allows the upgrade to continue.

## Recovery Notes

ZFSBootMenu is the pre-boot recovery interface for root snapshots and boot environments.

For file-level recovery, use ZFS snapshots directly, such as:

```bash
/home/.zfs/snapshot
```

Off-system replication and portable backups are separate layers and should be configured outside this base installer.

## Existing-system migration

Do not rerun the installer on an existing system. Use the reconciliation tool
to replace the legacy recursive policy and isolate volatile data:

```bash
./reconcile-existing-zfs.sh audit
sudo ./reconcile-existing-zfs.sh apply
sudo ./reconcile-existing-zfs.sh verify
```

The migration stops Docker and containerd while copying their data into
encrypted child datasets. It also moves `/local/development/tmp` into an
excluded child dataset. The container datasets have a combined 40 GiB quota;
the development tmp dataset has a 50 GiB quota.

The reconciliation tool also applies dataset-level guardrails: 175 GiB for the
root boot environment (including volatile children and snapshots), 250 GiB for
home, and 400 GiB for `/local/development`. Together these preserve roughly
95 GiB of pool headroom even if all three limits are reached.

The original directories remain as timestamped rollback copies, and the tool
does not destroy existing snapshots. Migrated systems use `autosnap_v2_*` and
`pre_update_v2_*` names, so automatic retention applies only to new snapshots;
the legacy recursive history remains untouched until an independent backup and
restore test are complete. Review the paths in
`/var/lib/arch-zfs-reconcile/rollback-directories.tsv` before removing any
rollback copy or pruning legacy snapshots.

## References

I'm not really that smart - I have much to learn.
This work was built on the shoulders of giants.
Huge shout-out and THANK YOU to the following:

* https://florianesser.ch/posts/20220714-arch-install-zbm/
* https://nwildner.com/posts/2025-09-03-zfs-setup/
* https://man.archlinux.org/man/alpm-hooks.5.en
