# Arch Linux Setup Tool

A comprehensive, menu-driven Arch Linux installer with LUKS encryption, Hyprland desktop environment, and complete dotfiles system.

## Quick Start

### Option 1: Interactive Menu System
```bash
# Download and run from Arch Linux live environment
curl -LO https://github.com/yourusername/arch-setup-tool/raw/main/setup.sh
chmod +x setup.sh
sudo ./setup.sh
```

### Option 2: Direct Installation (Legacy)
```bash
# Legacy single-script installation
curl -LO https://github.com/yourusername/arch-setup-tool/raw/main/install.sh
bash install.sh
```

## Features

- Automated end-to-end Arch Linux installation
- LUKS encryption + LVM setup
- Configurable partition schemes for different disk sizes
- Timeshift integration for system backups (except for compact scheme)
- Works on both VMs and bare metal
- Post-install script with desktop environments (GNOME, KDE, i3wm), PipeWire audio, LibreOffice, LightDM

## Partition Schemes

* compact: For 60-100GB disks: 8GB swap, rest for root (no /home, no timeshift)
* standard: For 512GB disks: 16GB swap, 150GB root, 200GB home, rest for timeshift
* massive: For 1TB+ disks: 16GB swap, 200GB root, rest split between home and timeshift

## Partition Layout

The script creates:

* efi: 1GiB partition (FAT32)
* boot: 5GiB partition (ext4)
* LVM on LUKS container with:
  * swap: 8GB or 16GB
  * root: 100%FREE (compact), 150GB (standard), or 200GB (massive)
  * home: Remaining LVM space (standard/massive only)
* Timeshift partition (for standard/massive schemes)

## Post-Install

Run `post_install_script.sh` on the installed system to set up:
- Desktop environment (GNOME minimal/full, KDE minimal/full, or i3wm)
- PipeWire audio stack
- LibreOffice
- LightDM display manager (supports X11 + Wayland sessions)
- Fonts (international + CJK + Indic)
- AUR apps via yay (browsers, VS Code, etc.)

## Requirements

* Arch Linux live ISO
* Internet connection
* Single disk with sufficient space

## Usage Notes

* Run from Arch live ISO environment
* Script requires root privileges
* Will completely erase the target disk