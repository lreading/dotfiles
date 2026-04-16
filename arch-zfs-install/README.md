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

By default, snapshots use a recursive `zroot` policy. This keeps root, home, and inherited `/local` datasets aligned under the same snapshot names.

Optional `/local` datasets can be given separate retention policies, but doing that changes restore semantics. A separate policy means the installer stops using one recursive root snapshot and creates explicit per-policy dataset snapshots instead. Only use that mode when dataset-aware ZFS restore procedures are acceptable.

## Recovery Notes

ZFSBootMenu is the pre-boot recovery interface for root snapshots and boot environments.

For file-level recovery, use ZFS snapshots directly, such as:

```bash
/home/.zfs/snapshot
```

Off-system replication and portable backups are separate layers and should be configured outside this base installer.

## References

I'm not really that smart - I have much to learn.
This work was built on the shoulders of giants.
Huge shout-out and THANK YOU to the following:

* https://florianesser.ch/posts/20220714-arch-install-zbm/
* https://nwildner.com/posts/2025-09-03-zfs-setup/

