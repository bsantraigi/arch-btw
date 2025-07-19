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

### Phase 2: Menu System & Integration ✅
*See: `menu_system_design.md` for detailed design*
- [x] Unified menu interface (`setup.sh`) ✅ Phase 2A
- [x] Modular operation handlers ✅ Phase 2A  
- [x] State management (mount/unmount detection) ✅ Phase 2A
- [x] Password confirmation system ✅ Phase 2A
- [x] Integration with install.sh functions ✅ Phase 2B
- [x] Complete partitioning workflow ✅ Phase 2B
- [x] Base system installation ✅ Phase 2B

### Phase 3: Hyprland Environment ✅
*See: `hyprland_implementation.md` for complete package list and configuration*
- [x] Remove GNOME/KDE options from post-install ✅ Phase 3A
- [x] Hyprland + Wayland ecosystem installation ✅ Phase 3A
- [x] Essential tools integration (see `hyprland_tools.md`) ✅ Phase 3A
- [x] Polkit setup for authentication ✅ Phase 3A
- [x] LDUR keybinding scheme implementation ✅ Phase 3A
- [x] Microsoft Edge + Brave browser installation ✅ Phase 3A

### Phase 4: Dotfiles System 📋
*See: `dotfiles_system_design.md` for migration strategy and structure*
- [ ] Dotfiles repository structure
- [ ] i3 → Hyprland config translation
- [ ] Public repo preparation
- [ ] Configuration deployment automation

### Phase 5: Finalization & Polish 📋
*See: `implementation_roadmap.md` for session-by-session breakdown*
- [ ] Workspace configuration (kitty default, browser setup)
- [ ] Vim keybindings for Hyprland (LDUR movement)
- [ ] VirtualBox integration
- [ ] Timeshift backup configuration

## Menu Operations

*See: `menu_system_design.md` for complete interface design and state management*

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

*See: `hyprland_implementation.md` for LDUR keybindings and workspace configuration*

1. Terminal (kitty)
2. Web browser
(Additional workspaces as needed)

## Development Roadmap

*See: `implementation_roadmap.md` for complete session-by-session development plan*

**Next Steps**: Phase 3 ✅ COMPLETED
**Current Phase**: Ready for Phase 4A (Dotfiles System) - Create dotfiles repository structure and i3 → Hyprland migration


