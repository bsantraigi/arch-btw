# Arch Linux Personal System Setup Tool

A comprehensive system setup tool for quick system replication with minimal user intervention. Designed for personal use with fixed, opinionated choices.

## Overview

**Target**: Arch Linux with encrypted LVM on LUKS + Hyprland desktop environment
**Philosophy**: Automated, minimal intervention, robust error handling

## Implementation Phases

### Phase 1: Core Infrastructure ✅ 
- [x] LUKS + LVM partitioning (`install.sh`)
- [x] Base OS installation
- [x] Reset/cleanup utilities (`reset.sh`)

### Phase 2: Menu System & Integration 🔄
- [ ] Unified menu interface (`setup.sh`)
- [ ] Modular operation handlers
- [ ] State management (mount/unmount detection)
- [ ] Password confirmation system

### Phase 3: Hyprland Environment 🔄
- [ ] Remove GNOME/KDE options from post-install
- [ ] Hyprland + Wayland ecosystem installation
- [ ] Essential tools integration (see `hyprland_implementation.md`)
- [ ] Polkit setup for authentication

### Phase 4: Dotfiles System 📋
- [ ] Dotfiles repository structure
- [ ] i3 → Hyprland config translation
- [ ] Public repo preparation
- [ ] Configuration deployment automation

### Phase 5: Finalization & Polish 📋
- [ ] Workspace configuration (kitty default, browser setup)
- [ ] Vim keybindings for Hyprland (LDUR movement)
- [ ] VirtualBox integration
- [ ] Timeshift backup configuration

## Menu Operations

**Main Menu**:
1. Setup/Recreate LUKS + Partition + LVM (auto-mount)
2. Unmount configuration 
3. Remount configuration (with password prompt)
4. Install Base OS + Software
5. Install Hyprland + Essential Tools
6. Deploy Dotfiles
7. System Status/Info

## Default Applications

- **Terminal**: Kitty (GPU-accelerated)
- **Browsers**: Microsoft Edge, Brave
- **File Manager**: Yazi (terminal), Thunar (GUI)
- **Editor**: VS Code, Vim

## Workspace Layout

1. Terminal (kitty)
2. Web browser
(Additional workspaces as needed)


