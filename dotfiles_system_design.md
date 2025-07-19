# Dotfiles System Design

## Overview
Transform existing i3 dotfiles to Hyprland, structure for public release, and automate deployment.

## Current State Analysis
- **Source**: Private i3 dotfiles repository
- **Target**: Public Hyprland dotfiles repository  
- **Migration**: i3 → Hyprland configuration translation
- **Deployment**: Automated installation integration

## Repository Structure

### Proposed Public Dotfiles Layout
```
dotfiles/
├── README.md                    # Public documentation
├── install.sh                   # Standalone dotfiles installer
├── hypr/                        # Hyprland configuration
│   ├── hyprland.conf           # Main config
│   ├── hyprpaper.conf          # Wallpaper management
│   ├── hyprlock.conf           # Screen lock
│   ├── hypridle.conf           # Idle management
│   └── keybindings.conf        # LDUR vim keybindings
├── waybar/                      # Status bar
│   ├── config                  # Waybar configuration
│   ├── style.css               # Styling
│   └── modules/                # Custom modules
├── rofi/                        # Application launcher
│   ├── config.rasi             # Main config
│   └── themes/                 # Custom themes
├── kitty/                       # Terminal configuration
│   ├── kitty.conf              # Main config
│   └── themes/                 # Color schemes
├── vim/                         # Vim configuration
│   ├── .vimrc                  # Main config
│   └── plugins/                # Plugin configs
├── shell/                       # Shell configuration
│   ├── .bashrc                 # Bash config
│   ├── .zshrc                  # Zsh config (if used)
│   └── aliases                 # Common aliases
├── applications/                # Desktop entries
│   └── virtualbox-root.desktop # VirtualBox as root
├── scripts/                     # Utility scripts
│   ├── screenshot.sh           # Screenshot utilities
│   ├── audio-control.sh        # Audio management
│   └── workspace-switch.sh     # Workspace utilities
└── assets/                      # Wallpapers, fonts, etc.
    ├── wallpapers/
    ├── fonts/
    └── icons/
```

## Migration Strategy (i3 → Hyprland)

### Configuration Mapping
| i3 Component | Hyprland Equivalent | Notes |
|--------------|-------------------|-------|
| `i3.conf` | `hyprland.conf` | Window management rules |
| `i3status/i3blocks` | `waybar` | Status bar |
| `dmenu/rofi` | `rofi-wayland` | Application launcher |
| `i3lock` | `hyprlock` | Screen locking |
| `feh` (wallpaper) | `hyprpaper` | Wallpaper management |

### Key Translation Areas
1. **Keybindings**: Adapt i3 bindings to Hyprland syntax
2. **Window Rules**: Convert i3 window classes to Hyprland rules
3. **Workspace Management**: Translate workspace assignments
4. **Autostart**: Convert i3 exec commands to Hyprland exec-once

### Example Translation
```bash
# i3 config
bindsym $mod+h focus left
bindsym $mod+j focus down  
bindsym $mod+k focus up
bindsym $mod+l focus right

# Hyprland equivalent (LDUR)
bind = SUPER, L, movefocus, l  # Right
bind = SUPER, D, movefocus, d  # Down
bind = SUPER, U, movefocus, u  # Up  
bind = SUPER, R, movefocus, r  # Left
```

## Deployment Integration

### Dotfiles Installer (`dotfiles/install.sh`)
```bash
#!/bin/bash
# Standalone dotfiles installer
# Can be run independently or called from main setup

install_dotfiles() {
    local source_dir="$1"
    local backup_existing="${2:-true}"
    
    # Backup existing configs
    if [[ "$backup_existing" == "true" ]]; then
        backup_configs
    fi
    
    # Deploy configurations
    deploy_hyprland_config
    deploy_waybar_config  
    deploy_application_configs
    deploy_scripts
    
    # Set permissions
    set_executable_permissions
}
```

### Integration with Main Setup
```bash
# In main setup.sh
op_deploy_dotfiles() {
    echo "Deploying dotfiles..."
    
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        clone_dotfiles_repo
    fi
    
    cd "$DOTFILES_DIR"
    ./install.sh
}
```

## Public Repository Preparation

### Documentation Requirements
1. **README.md**: Installation instructions, screenshots
2. **CHANGELOG.md**: Version history and updates
3. **LICENSE**: Open source license (MIT/GPL)
4. **CONTRIBUTING.md**: Contribution guidelines

### Security Considerations
- Remove any personal information
- Sanitize file paths and usernames
- Review for sensitive configurations
- Generic default values

### Customization Framework
```bash
# User customization file
~/.config/dotfiles/user.conf

# Example contents:
TERMINAL_FONT="JetBrains Mono"
WALLPAPER_PATH="$HOME/Pictures/wallpaper.jpg"
BROWSER_DEFAULT="brave"
```

## Implementation Phases

### Phase 4A: Repository Preparation
- Extract and sanitize i3 configs from private repo
- Create public repository structure
- Write documentation

### Phase 4B: Configuration Translation  
- Convert i3 configs to Hyprland equivalents
- Implement LDUR keybinding scheme
- Test configuration compatibility

### Phase 4C: Deployment Automation
- Create standalone dotfiles installer
- Integrate with main setup system
- Add backup/restore functionality

### Phase 4D: Public Release Preparation
- Final security review
- Documentation completion
- Version tagging and release

## Dependencies and Integration

### Required Packages (automatically installed)
- `git` (for cloning repository)
- `stow` (optional, for symlink management)
- All Hyprland ecosystem packages

### Integration Points
- Called from main setup menu option 6
- Can be run independently on existing systems
- Backup existing configurations before deployment
- Validate required packages are installed

## Testing Strategy
1. **VM Testing**: Test on clean Arch installation
2. **Backup Testing**: Verify backup/restore functionality  
3. **Standalone Testing**: Test dotfiles installer independently
4. **Migration Testing**: Test i3 → Hyprland conversion accuracy
