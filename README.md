# arch-btw

An automated Arch Linux installer with LUKS on LVM setup.

## Features

- Automated end-to-end Arch Linux installation
- LUKS encryption + LVM setup
- Configurable partition schemes for different disk sizes
- Timeshift integration for system backups (except for compact scheme)
- Works on both VMs and bare metal

## Quick Start

Download and run the script from the Arch Linux live environment:

```bash
curl -sL https://github.com/bsantraigi/arch-btw/raw/main/install.sh | bash
```

# Partition Schemes

* compact: For 60-100GB disks: 8GB swap, 40GB root, rest for home (no timeshift)
* standard: For 512GB disks: 16GB swap, 150GB root, 200GB home, 180GB timeshift
* massive: For 1TB+ disks: 16GB swap, 200GB root, rest split between home and timeshift

# Partition Layout
The script creates:

* efi: 1GiB partition (FAT32)
* boot: 5GiB partition (ext4)
* LVM on LUKS container with:
* swap: 8GB or 16GB
* root: 40GB, 150GB, or 200GB
* home: Remaining space in LVM
* Timeshift partition (for standard/massive schemes)

# Requirements
* Arch Linux live ISO
* Internet connection
* Single disk with sufficient space

# Usage Notes
* Run from Arch live ISO environment
* Script requires root privileges
* Will completely erase the target disk