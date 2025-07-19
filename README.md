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

### Core Installation
- **Interactive Menu System**: Step-by-step guided installation
- **LUKS + LVM Encryption**: Full disk encryption with logical volume management
- **Flexible Partitioning**: Multiple schemes for different disk sizes (60GB-1TB+)
- **State Management**: Resume installation from any point
- **Error Recovery**: Robust error handling and recovery options

### Desktop Environment
- **Hyprland-Only Setup**: Modern Wayland compositor with LDUR keybindings
- **Complete Wayland Stack**: Waybar, Rofi, Kitty, PipeWire integration
- **No GNOME/KDE**: Lightweight, efficient desktop environment
- **Microsoft Edge + Brave**: Modern browsers with AUR integration
- **VirtualBox Integration**: Polkit-based root access support

### Dotfiles System
- **Comprehensive Configs**: Complete Hyprland, Waybar, Kitty configurations
- **LDUR Keybinding Scheme**: Vim-style H/J/K/L directional navigation
- **Backup Support**: Automatic backup of existing configurations
- **Standalone Installation**: Can be used independently of main installer

## Menu Operations

1. **Setup Disk Partitions** - Create LUKS+LVM partition scheme
2. **Install Base System** - Install Arch Linux base system with user creation
3. **Install Hyprland** - Install complete Hyprland desktop environment
4. **Setup Timeshift** - Configure system backup solution
5. **Configure VirtualBox** - Setup VirtualBox with root access
6. **View System Status** - Check installation state and system information
7. **Deploy Dotfiles** - Install comprehensive Hyprland configuration files
8. **Exit** - Exit the setup tool

## Partition Schemes

### Compact (60-100GB)
- **Target**: Small SSDs, VMs
- **Layout**: 8GB swap, 40GB root, rest for home
- **Features**: No Timeshift (space constraints)

### Standard (250-512GB)
- **Target**: Standard laptops/desktops
- **Layout**: 16GB swap, 150GB root, 200GB home, rest for Timeshift
- **Features**: Full backup support

### Massive (1TB+)
- **Target**: Large storage systems
- **Layout**: 16GB swap, 200GB root, balanced home/Timeshift split
- **Features**: Extended backup retention

## Partition Layout Details

All schemes create:
- **EFI**: 1GB (FAT32) - UEFI boot partition
- **Boot**: 5GB (ext4) - Kernel and initramfs storage
- **LUKS Container**: Remainder of disk containing LVM with:
  - **Swap**: 8-16GB logical volume
  - **Root**: 40-200GB logical volume
  - **Home**: User data storage
  - **Timeshift**: Backup storage (standard/massive only)

## LDUR Keybinding Scheme

The dotfiles implement a consistent LDUR (Left, Down, Up, Right) navigation scheme:

### Window Management
- `Super + H/J/K/L` - Focus left/down/up/right
- `Super + Shift + H/J/K/L` - Move windows
- `Super + Ctrl + H/J/K/L` - Resize windows

### Applications
- `Super + Return` - Terminal (Kitty)
- `Super + R` - Launcher (Rofi)
- `Super + E` - File manager
- `Super + B` - Browser (Edge)

### System
- `Super + Q` - Close window
- `Super + M` - Exit Hyprland
- `Super + L` - Lock screen
- `Print` - Screenshot

## Repository Structure

```
arch-setup-tool/
├── setup.sh              # Main menu-driven installer
├── install.sh             # Legacy direct installer
├── post_install_script.sh # Hyprland environment installer
├── reset.sh               # System reset utility
├── lib/                   # Modular installation libraries
│   ├── state.sh           # System state detection
│   ├── utils.sh           # Utilities and colors
│   ├── partitions.sh      # Partition management
│   ├── install.sh         # Base system installation
│   └── hyprland.sh        # Hyprland installation
└── dotfiles/              # Complete Hyprland configuration
    ├── hypr/              # Hyprland window manager config
    ├── waybar/            # Status bar configuration
    ├── kitty/             # Terminal configuration
    ├── rofi/              # Application launcher
    ├── vim/               # Vim editor configuration
    ├── shell/             # Shell aliases and functions
    ├── applications/      # Desktop application entries
    ├── scripts/           # Utility scripts
    └── dotfiles-install.sh # Standalone dotfiles installer
```

## Requirements

- **Boot Environment**: Arch Linux live ISO
- **Internet**: Active connection for package downloads
- **Storage**: 60GB minimum (250GB+ recommended)
- **Architecture**: x86_64 UEFI systems
- **Memory**: 2GB+ RAM (4GB+ recommended)

## Advanced Usage

### State Management
The installer tracks system state and allows resuming from interruption:
- `CLEAN` - Fresh system, ready for partitioning
- `PARTITIONED` - Disks ready, can install base system
- `MOUNTED` - Partitions mounted, ready for installation
- `INSTALLED` - Base system ready for desktop environment

### Custom Configuration
- Edit `lib/` modules for custom installation behavior
- Modify `dotfiles/` for personalized configurations
- Use `setup.sh` operations individually as needed

### Debugging
```bash
# Enable debug output
bash -x setup.sh

# Check system state
./setup.sh # Use operation 6 for system info

# View logs
journalctl -f
```

## Contributing

1. Fork the repository
2. Test changes in virtual machine
3. Document modifications
4. Submit pull request

## License

This project is provided as-is for educational and personal use. Feel free to modify and distribute according to your needs.

## Credits

- Arch Linux community for excellent documentation
- Hyprland developers for the modern Wayland compositor
- Contributors to Waybar, Kitty, and other essential tools