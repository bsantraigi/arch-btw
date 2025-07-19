# Hyprland Implementation Plan

## Overview
Replace GNOME/KDE with Hyprland-only setup. Focus on Wayland-native tools with vim keybindings integration.

## Package Categories

### 1. Core Hyprland Setup
```bash
# Core packages
hyprland                    # Window manager
hyprpaper                   # Wallpaper utility  
hyprlock                    # Screen locker
hypridle                    # Idle management
xdg-desktop-portal-hyprland # Portal for screen sharing
```

### 2. Essential Wayland Tools
```bash
# Status bar and launcher
waybar                      # Status bar
rofi-wayland               # Application launcher

# Terminal and file management  
kitty                      # Terminal emulator
yazi                       # Terminal file manager
thunar                     # GUI file manager

# Audio and media
pipewire pipewire-pulse    # Audio system
wireplumber                # Audio session manager
pavucontrol                # Audio control GUI

# Screenshots and clipboard
grim slurp                 # Screenshot foundation
grimblast-git              # Hyprland screenshot tool  
swappy                     # Screenshot editor
wl-clipboard               # Wayland clipboard
cliphist                   # Clipboard history
```

### 3. Applications
```bash
# Browsers (as requested)
microsoft-edge-stable-bin  # Microsoft Edge (AUR)
brave-bin                  # Brave browser (AUR)

# Development
visual-studio-code-bin     # VS Code (AUR)
vim                        # Terminal editor

# System monitoring
btop                       # System monitor
```

### 4. System Integration
```bash
# Authentication and mounting
polkit                     # Authentication framework
polkit-gnome              # GUI authentication agent
udisks2                    # Disk mounting
```

## Configuration Structure

### Hyprland Config (`~/.config/hypr/`)
```
hyprland.conf              # Main config
hyprpaper.conf            # Wallpaper config
hyprlock.conf             # Lock screen config
hypridle.conf             # Idle management
```

### Vim Keybindings Integration
```bash
# Movement (LDUR instead of HJKL)
bind = SUPER, L, movefocus, l  # Right
bind = SUPER, D, movefocus, d  # Down  
bind = SUPER, U, movefocus, u  # Up
bind = SUPER, R, movefocus, r  # Left (R for reverse)

# Window movement
bind = SUPER_SHIFT, L, movewindow, l
bind = SUPER_SHIFT, D, movewindow, d
bind = SUPER_SHIFT, U, movewindow, u  
bind = SUPER_SHIFT, R, movewindow, r

# Workspace switching (vim-style)
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
# ... etc
```

### Workspace Configuration
```bash
# Workspace names with icons
workspace = 1, name:1:, default:true
workspace = 2, name:2:

# Default applications  
exec-once = kitty            # Terminal on workspace 1
windowrule = workspace 2, class:^(brave)$
windowrule = workspace 2, class:^(microsoft-edge)$
```

## VirtualBox Integration

### Menu Entry Creation
Location: `~/.local/share/applications/virtualbox-root.desktop`
```ini
[Desktop Entry]
Name=VirtualBox (as root)
Comment=Run VirtualBox with root privileges
Exec=pkexec VirtualBox %U
Icon=virtualbox
Type=Application
Categories=System;Emulator;
```

### Polkit Rule
Location: `/etc/polkit-1/rules.d/50-virtualbox.rules`
```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.policykit.exec" &&
        action.lookup("program") == "/usr/bin/VirtualBox" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
```

## Implementation Phases

### Phase 3A: Package Installation
- Remove GNOME/KDE from post_install_script.sh
- Add Hyprland package function
- Install Wayland ecosystem

### Phase 3B: Base Configuration  
- Create default Hyprland config
- Set up vim keybindings (LDUR)
- Configure workspace assignments

### Phase 3C: System Integration
- Set up polkit authentication
- Configure VirtualBox desktop entry
- Audio/video pipeline setup

### Phase 3D: Application Integration
- Browser installations (Edge, Brave)
- Development tools (VS Code, vim)
- System utilities (btop, yazi)

## Keybinding Scheme (LDUR)

**Philosophy**: Use LDUR for directional movement (Left, Down, Up, Right)
- More intuitive than HJKL for non-vim users
- Maintains vim-style efficiency
- Consistent across all directional operations

```bash
# Focus movement: SUPER + LDUR
L = Right, D = Down, U = Up, R = Left (reverse)

# Window movement: SUPER + SHIFT + LDUR  
# Resize: SUPER + CTRL + LDUR
# Workspace: SUPER + [1-9]
```

## File Organization
```
hyprland_setup.sh          # Installation script
configs/
├── hypr/
│   ├── hyprland.conf      # Main config
│   ├── hyprpaper.conf     # Wallpaper
│   └── keybindings.conf   # LDUR keybindings
├── waybar/
│   └── config             # Status bar config
└── applications/
    └── virtualbox-root.desktop
```
