# Copilot Instructions

## Project Overview

Automated Arch Linux installer with LUKS-on-LVM encryption. Bash scripts run from a live ISO, handling disk setup through post-install desktop configuration.

## Architecture

Install pipeline (sequential, each script is standalone):

1. `install.sh` — Main installer: partitioning, LUKS encryption, LVM, base system, GRUB. Runs from live ISO.
2. `post_install_script.sh` — Desktop env (GNOME/KDE/i3wm), audio, office, fonts, AUR packages, LightDM, root hardening. Runs in chroot or on installed system.
3. `reset.sh` — Teardown: unmount/close LVM+LUKS for retrying installation.

Key constants:
- Volume group: `SysVG`, LUKS mapper: `cryptlvm`
- Partition schemes: compact (60-100GB), standard (512GB), massive (1TB+)
- NVMe naming (`p1`, `p2`) vs SATA (`1`, `2`) handled via regex on disk path
- AUR via `yay` with temporary `builduser` when running as root

## Conventions

- `set -e` in all scripts
- `declare -A` associative arrays for menu options
- User input gathered upfront in `get_user_input()`, then non-interactive execution
- Function naming: `verb_noun()` (e.g., `setup_encryption`, `create_partitions`, `install_fonts`)
- Helper functions (`install_yay`, `install_aur_packages`) intentionally duplicated across scripts to keep each self-contained
- Design for multiple environments: VMs, bare metal, chroot detection
- `pacman -S --noconfirm` for unattended installs, group related packages in single calls

## Testing

No automated tests. Test in VM:
```bash
bash -x install.sh    # debug mode
bash reset.sh         # clean state before retry
```
