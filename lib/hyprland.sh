#!/bin/bash

# Hyprland installation and setup functions

install_yay() {
    if command -v yay &>/dev/null; then
        echo "yay already installed"
        return
    fi
    
    echo "Installing yay AUR helper..."
    
    # Create build user if running as root
    if [[ $EUID -eq 0 ]]; then
        if ! id -u builduser &>/dev/null; then
            useradd -r -m -s /bin/bash builduser
            echo "builduser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
        fi
        
        sudo -u builduser bash << 'EOF'
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
EOF
    else
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
    fi
    
    rm -rf /tmp/yay
}

install_aur_packages() {
    local packages=("$@")
    
    if [[ $EUID -eq 0 ]]; then
        sudo -u builduser yay -S --noconfirm "${packages[@]}"
    else
        yay -S --noconfirm "${packages[@]}"
    fi
}

install_hyprland_core() {
    echo "Installing Hyprland core packages..."
    
    # Core Hyprland ecosystem
    pacman -S --noconfirm \
        hyprland \
        hyprpaper \
        hyprlock \
        hypridle \
        xdg-desktop-portal-hyprland \
        qt5-wayland qt6-wayland
}

install_wayland_tools() {
    echo "Installing Wayland ecosystem tools..."
    
    # Status bar and launcher
    pacman -S --noconfirm \
        waybar \
        rofi-wayland
    
    # Terminal and file management
    pacman -S --noconfirm \
        kitty \
        thunar \
        thunar-volman \
        gvfs
    
    # Audio system
    pacman -S --noconfirm \
        pipewire \
        pipewire-pulse \
        pipewire-jack \
        wireplumber \
        pavucontrol
    
    # Screenshots and clipboard
    pacman -S --noconfirm \
        grim \
        slurp \
        swappy \
        wl-clipboard
    
    # Notifications and authentication
    pacman -S --noconfirm \
        dunst \
        polkit \
        polkit-gnome
    
    # System utilities
    pacman -S --noconfirm \
        btop \
        htop \
        vim
}

install_browsers() {
    echo "Installing browsers..."
    
    # Install AUR browsers
    install_aur_packages microsoft-edge-stable-bin brave-bin
}

install_development_tools() {
    echo "Installing development tools..."
    
    # VS Code and additional tools
    install_aur_packages visual-studio-code-bin
    
    # Terminal file manager (yazi - if available in repos or AUR)
    if pacman -Ss yazi &>/dev/null; then
        pacman -S --noconfirm yazi
    else
        install_aur_packages yazi-bin
    fi
}

install_additional_tools() {
    echo "Installing additional tools..."
    
    # AUR screenshot tool
    install_aur_packages grimblast-git
    
    # Clipboard history
    install_aur_packages cliphist
    
    # Gaming tools (optional)
    if confirm_operation "Install gaming tools (GameMode, MangoHud)?"; then
        pacman -S --noconfirm gamemode
        install_aur_packages mangohud
    fi
}

setup_polkit() {
    echo "Setting up polkit authentication..."
    
    # Create polkit configuration for VirtualBox
    mkdir -p /etc/polkit-1/rules.d
    cat > /etc/polkit-1/rules.d/50-virtualbox.rules << 'EOF'
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.policykit.exec" &&
        action.lookup("program") == "/usr/bin/VirtualBox" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF
    
    # Create VirtualBox desktop entry for root execution
    mkdir -p /usr/local/share/applications
    cat > /usr/local/share/applications/virtualbox-root.desktop << 'EOF'
[Desktop Entry]
Name=VirtualBox (as root)
Comment=Run VirtualBox with root privileges
Exec=pkexec VirtualBox %U
Icon=virtualbox
Type=Application
Categories=System;Emulator;
EOF
}

setup_locale() {
    echo "Setting up comprehensive locale support..."
    
    # Add locales
    cat >> /etc/locale.gen << 'EOF'
en_US.UTF-8 UTF-8
hi_IN UTF-8
bn_IN UTF-8
ja_JP.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8
EOF
    
    locale-gen
    localectl set-locale LANG=en_US.UTF-8
}

setup_timezone() {
    echo "Setting timezone to Asia/Kolkata..."
    timedatectl set-timezone Asia/Kolkata
}

setup_fonts() {
    echo "Installing comprehensive font packages..."
    
    # Base fonts
    pacman -S --noconfirm \
        ttf-dejavu ttf-liberation noto-fonts noto-fonts-emoji \
        ttf-roboto ttf-opensans adobe-source-code-pro-fonts \
        ttf-jetbrains-mono
    
    # International fonts
    pacman -S --noconfirm \
        noto-fonts-cjk noto-fonts-extra \
        ttf-indic-otf
    
    # AUR fonts
    echo "Installing AUR font packages..."
    install_aur_packages ttf-ms-fonts
}

enable_services() {
    echo "Enabling essential services..."
    
    # Enable audio services
    systemctl --user enable pipewire pipewire-pulse wireplumber
    
    # Enable polkit agent (will be started by Hyprland)
    # This is handled in Hyprland config with exec-once
}

create_hyprland_config() {
    local user_home="$1"
    
    echo "Creating basic Hyprland configuration..."
    
    # Create config directory
    mkdir -p "$user_home/.config/hypr"
    
    # Basic Hyprland config with LDUR keybindings
    cat > "$user_home/.config/hypr/hyprland.conf" << 'EOF'
# Hyprland Configuration
# See https://wiki.hyprland.org/Configuring/Configuring-Hyprland/

# Monitor configuration
monitor=,preferred,auto,auto

# Input configuration
input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = no
    }
    sensitivity = 0
}

# General settings
general {
    gaps_in = 5
    gaps_out = 20
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
    allow_tearing = false
}

# Decoration
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
    }
    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# Animations
animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# Layouts
dwindle {
    pseudotile = yes
    preserve_split = yes
}

# Window rules
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(blueman-manager)$
windowrule = workspace 2, ^(brave-browser)$
windowrule = workspace 2, ^(microsoft-edge)$

# Keybindings (LDUR scheme)
$mainMod = SUPER

# Movement (LDUR = Left, Down, Up, Right)
bind = $mainMod, L, movefocus, r
bind = $mainMod, D, movefocus, d  
bind = $mainMod, U, movefocus, u
bind = $mainMod, R, movefocus, l

# Move windows (LDUR)
bind = $mainMod SHIFT, L, movewindow, r
bind = $mainMod SHIFT, D, movewindow, d
bind = $mainMod SHIFT, U, movewindow, u
bind = $mainMod SHIFT, R, movewindow, l

# Resize windows (LDUR)
bind = $mainMod CTRL, L, resizeactive, 10 0
bind = $mainMod CTRL, R, resizeactive, -10 0
bind = $mainMod CTRL, U, resizeactive, 0 -10
bind = $mainMod CTRL, D, resizeactive, 0 10

# Application shortcuts
bind = $mainMod, Q, exec, kitty
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, SPACE, exec, rofi -show drun
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,

# Workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move active window to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Screenshots
bind = , PRINT, exec, grimblast copy area
bind = SHIFT, PRINT, exec, grimblast save area

# Audio controls
bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindl = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindl = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+

# Autostart
exec-once = waybar
exec-once = hyprpaper
exec-once = dunst
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = wl-paste --watch cliphist store
EOF

    # Set ownership
    chown -R $(stat -c %u:%g "$user_home") "$user_home/.config"
}

# Main Hyprland installation function
install_hyprland_environment() {
    local username="$1"
    local user_home="/home/$username"
    
    print_step "Installing Hyprland Environment"
    
    # Update system first
    print_info "Updating package database..."
    pacman -Sy
    
    # Install yay for AUR packages
    install_yay
    
    # Core installations
    install_hyprland_core
    install_wayland_tools
    install_browsers
    install_development_tools
    install_additional_tools
    
    # System setup
    setup_locale
    setup_timezone
    setup_fonts
    setup_polkit
    enable_services
    
    # Create user configuration
    create_hyprland_config "$user_home"
    
    print_success "Hyprland environment installation completed!"
    print_info "Reboot and select Hyprland from the display manager"
}
