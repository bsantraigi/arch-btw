# Implementation Roadmap

## Phase Overview

This roadmap provides a sequential approach to implementing the complete system setup tool. Each phase builds on the previous one and can be completed in separate development sessions.

## Phase 1: ✅ COMPLETED
**Core Infrastructure**
- [x] LUKS + LVM partitioning system
- [x] Base OS installation automation  
- [x] Reset/cleanup utilities
- [x] Multi-scheme partition support

## Phase 2: Menu System & Integration 
**🎯 PRIORITY: HIGH**

### Phase 2A: Menu Framework (Session 1)
**Files to create/modify:**
- `setup.sh` - Main menu interface
- `lib/state.sh` - System state detection
- `lib/utils.sh` - Common utilities

**Key features:**
- State-aware menu system
- Password confirmation with retry
- Modular operation structure
- Error handling framework

**Copilot session tasks:**
1. Create basic menu structure with state detection
2. Implement password confirmation system
3. Add error handling and validation
4. Test menu navigation and state changes

### Phase 2B: Integration with Existing Code (Session 2)  
**Files to modify:**
- Refactor `install.sh` into modular functions
- Move partition operations to `lib/partitions.sh`
- Move base installation to `lib/install.sh`  
- Update `setup.sh` to use modular functions

**Copilot session tasks:**
1. Extract reusable functions from install.sh
2. Create modular library structure  
3. Update setup.sh to call extracted functions
4. Test full installation flow through menu

## Phase 3: Hyprland Environment
**🎯 PRIORITY: HIGH**

### Phase 3A: Package Management (Session 3)
**Files to create/modify:**
- `lib/hyprland.sh` - Hyprland installation functions
- Modify `post_install_script.sh` - Remove GNOME/KDE, add Hyprland

**Key features:**
- Complete Hyprland ecosystem installation
- AUR package management (Edge, Brave)
- Essential Wayland tools

**Copilot session tasks:**
1. Remove GNOME/KDE options from post-install
2. Create Hyprland package installation function
3. Add Microsoft Edge and Brave installation
4. Test package installation process

### Phase 3B: Base Configuration (Session 4)
**Files to create:**
- `configs/hypr/hyprland.conf` - Base Hyprland config
- `configs/hypr/keybindings.conf` - LDUR vim keybindings  
- `configs/waybar/config` - Status bar configuration

**Copilot session tasks:**
1. Create minimal working Hyprland configuration
2. Implement LDUR keybinding scheme
3. Set up basic waybar configuration
4. Test Hyprland startup and basic functionality

### Phase 3C: System Integration (Session 5)
**Files to create:**
- `configs/applications/virtualbox-root.desktop`
- Polkit configuration files
- Audio/video pipeline setup

**Copilot session tasks:**
1. Set up polkit authentication system
2. Create VirtualBox root menu entry
3. Configure audio pipeline (PipeWire)
4. Test system integration features

## Phase 4: Dotfiles System
**🎯 PRIORITY: MEDIUM**

### Phase 4A: Repository Structure (Session 6)
**New repository setup:**
- Create public dotfiles repository structure  
- Extract and sanitize configurations from private i3 repo
- Set up documentation framework

**Copilot session tasks:**
1. Create dotfiles repository structure
2. Write README and documentation templates
3. Set up basic installation script
4. Prepare for i3 → Hyprland migration

### Phase 4B: Configuration Migration (Session 7)
**Files to create/migrate:**
- Convert i3 configs to Hyprland format
- Update keybindings to LDUR scheme
- Migrate application configurations

**Copilot session tasks:**
1. Translate i3 window management to Hyprland
2. Convert status bar configuration
3. Update application launcher settings  
4. Test migrated configurations

### Phase 4C: Deployment Integration (Session 8)
**Files to modify:**
- `lib/dotfiles.sh` - Dotfiles deployment functions
- `setup.sh` - Add dotfiles menu option
- Integration testing

**Copilot session tasks:**
1. Create dotfiles deployment automation
2. Add backup/restore functionality
3. Integrate with main setup menu
4. Test complete deployment process

## Phase 5: Finalization & Polish
**🎯 PRIORITY: LOW**

### Phase 5A: Workspace Configuration (Session 9)
**Features to implement:**
- Default application assignments
- Workspace icons and naming
- Kitty as default terminal setup

**Copilot session tasks:**
1. Configure workspace assignments
2. Set up application defaults
3. Create workspace management scripts
4. Test workspace switching and assignments

### Phase 5B: Final Integration (Session 10)
**Features to implement:**
- Timeshift backup configuration
- Final testing and bug fixes
- Documentation updates

**Copilot session tasks:**
1. Set up Timeshift integration
2. Complete end-to-end testing
3. Fix any remaining issues
4. Update all documentation

## Development Strategy

### Session Planning
- **Duration**: Each session should be ~1-2 hours of focused work
- **Scope**: Complete one phase section per session
- **Testing**: Each session should end with working functionality
- **Documentation**: Update relevant docs at end of each session

### Dependencies
- **Phase 2** must complete before Phase 3
- **Phase 3A** must complete before 3B/3C
- **Phase 4** can partially overlap with Phase 3
- **Phase 5** requires all previous phases

### Testing Approach
- **VM Testing**: Use VirtualBox/QEMU for testing
- **Incremental**: Test after each session
- **Backup**: Keep working versions before major changes
- **Documentation**: Update plan.md after each phase

## Risk Mitigation

### Potential Issues
1. **AUR packages failing**: Have fallback package options
2. **Hyprland compatibility**: Test on multiple systems
3. **Dotfiles conflicts**: Implement robust backup system
4. **Menu state confusion**: Clear state indicators

### Backup Strategy
- Keep working versions tagged in git
- Test on disposable VM instances
- Document rollback procedures
- Maintain compatibility with existing install.sh
