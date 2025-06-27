#!/bin/bash
set -e

# Hyprland component packages
declare -A hypr_components=(
    [core]="hyprland xdg-desktop-portal-hyprland"
    [tools]="waybar rofi-wayland swww grim slurp wl-clipboard cliphist"
    [audio]="pipewire pipewire-pulse wireplumber pavucontrol"
    [notifications]="dunst libnotify"
    [auth]="polkit-kde-agent"
    [lock]="swaylock-effects"
    [apps]="nautilus kitty thunar"
)

install_yay_if_needed() {
    if ! command -v yay &>/dev/null; then
        echo "Installing yay AUR helper..."
        
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
    fi
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
    echo "Installing Hyprland and core components..."
    
    # Official repo packages
    pacman -S --noconfirm ${hypr_components[core]} ${hypr_components[tools]} \
        ${hypr_components[audio]} ${hypr_components[notifications]} \
        ${hypr_components[auth]} ${hypr_components[apps]}
    
    # AUR packages
    # install_aur_packages swaylock-effects hyprpicker-git wlogout
    install_aur_packages hyprpicker-git wlogout
}

create_hyprland_config() {
    local config_dir="$HOME/.config/hypr"
    mkdir -p "$config_dir"
    
    cat > "$config_dir/hyprland.conf" << 'EOF'
# Hyprland Config - Summer Night Theme

# Monitor setup
monitor=,preferred,auto,1
monitor=DP-1,2560x1440@144,0x0,1
monitor=HDMI-A-1,1920x1080@60,2560x0,1

# Startup
exec-once = waybar
exec-once = swww init
exec-once = dunst
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = swayidle -w timeout 300 'swaylock-effects --screenshots --clock --indicator --effect-blur 7x5'

# Summer night wallpaper
exec-once = swww img ~/Pictures/wallpaper.jpg --transition-type wipe --transition-duration 2

# Input config
input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = true
    }
    sensitivity = 0
}

# General settings
general {
    gaps_in = 8
    gaps_out = 12
    border_size = 2
    col.active_border = rgba(ff6b6bff) rgba(4ecdc4ff) 45deg
    col.inactive_border = rgba(2d3748aa)
    layout = dwindle
    allow_tearing = false
}

# Decoration
decoration {
    rounding = 12
    
    blur {
        enabled = true
        size = 8
        passes = 3
        new_optimizations = true
        xray = true
        ignore_opacity = false
    }
    
    drop_shadow = true
    shadow_range = 15
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
    col.shadow_inactive = rgba(1a1a1a88)
}

# Animations - Summer night smooth
animations {
    enabled = true
    bezier = summer, 0.25, 0.9, 0.1, 1.02
    bezier = night, 0.16, 1, 0.3, 1
    
    animation = windows, 1, 6, summer, slide
    animation = windowsOut, 1, 4, night, slide
    animation = border, 1, 8, summer
    animation = borderangle, 1, 8, summer
    animation = fade, 1, 4, summer
    animation = workspaces, 1, 5, summer, slidevert
}

# Dwindle layout
dwindle {
    pseudotile = true
    preserve_split = true
}

# Master layout
master {
    new_is_master = true
}

# Gestures
gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
}

# Misc
misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
    vfr = true
}

# Window rules
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(nm-connection-editor)$
windowrule = float, ^(thunar)$
windowrule = size 800 600, ^(thunar)$
windowrule = center, ^(thunar)$

# Workspace rules
workspace = 1, monitor:DP-1, default:true
workspace = 2, monitor:DP-1
workspace = 3, monitor:DP-1
workspace = 4, monitor:DP-1
workspace = 5, monitor:HDMI-A-1
workspace = 6, monitor:HDMI-A-1
workspace = 7, monitor:HDMI-A-1
workspace = 8, monitor:HDMI-A-1
workspace = 9, monitor:HDMI-A-1
workspace = 10, monitor:HDMI-A-1

# Keybindings
$mod = SUPER

# Applications
bind = $mod, RETURN, exec, kitty
bind = $mod, D, exec, rofi -show drun -theme ~/.config/rofi/summer-night.rasi
bind = $mod, E, exec, thunar
bind = $mod, B, exec, brave
bind = $mod, C, exec, code

# Window management (vim-like)
bind = $mod, H, movefocus, l
bind = $mod, L, movefocus, r
bind = $mod, K, movefocus, u
bind = $mod, J, movefocus, d

bind = $mod SHIFT, H, movewindow, l
bind = $mod SHIFT, L, movewindow, r
bind = $mod SHIFT, K, movewindow, u
bind = $mod SHIFT, J, movewindow, d

bind = $mod, Q, killactive
bind = $mod, F, fullscreen
bind = $mod, V, togglefloating
bind = $mod, P, pseudo
bind = $mod, S, togglesplit

# Workspaces
bind = $mod, 1, workspace, 1
bind = $mod, 2, workspace, 2
bind = $mod, 3, workspace, 3
bind = $mod, 4, workspace, 4
bind = $mod, 5, workspace, 5
bind = $mod, 6, workspace, 6
bind = $mod, 7, workspace, 7
bind = $mod, 8, workspace, 8
bind = $mod, 9, workspace, 9
bind = $mod, 0, workspace, 10

bind = $mod SHIFT, 1, movetoworkspace, 1
bind = $mod SHIFT, 2, movetoworkspace, 2
bind = $mod SHIFT, 3, movetoworkspace, 3
bind = $mod SHIFT, 4, movetoworkspace, 4
bind = $mod SHIFT, 5, movetoworkspace, 5
bind = $mod SHIFT, 6, movetoworkspace, 6
bind = $mod SHIFT, 7, movetoworkspace, 7
bind = $mod SHIFT, 8, movetoworkspace, 8
bind = $mod SHIFT, 9, movetoworkspace, 9
bind = $mod SHIFT, 0, movetoworkspace, 10

# Monitor workspace movement
bind = $mod, M, movecurrentworkspacetomonitor, +1
bind = $mod, N, movecurrentworkspacetomonitor, -1

# Special keys
bind = $mod, ESCAPE, exec, swaylock-effects --screenshots --clock --indicator --effect-blur 7x5
bind = $mod, PAUSE, exec, wlogout
bind = , PRINT, exec, grim -g "$(slurp)" - | wl-copy && notify-send "Screenshot" "Copied to clipboard"
bind = SHIFT, PRINT, exec, grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png && notify-send "Screenshot" "Saved to Pictures"

# Volume and brightness
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bind = , XF86MonBrightnessUp, exec, brightnessctl set 10%+
bind = , XF86MonBrightnessDown, exec, brightnessctl set 10%-

# Mouse bindings
bindm = $mod, mouse:272, movewindow
bindm = $mod, mouse:273, resizewindow

# Workspace auto-launch apps
exec-once = [workspace 1 silent] kitty
exec-once = [workspace 2 silent] brave
exec-once = [workspace 3 silent] thunar
exec-once = [workspace 4 silent] code
EOF
}

create_waybar_config() {
    local config_dir="$HOME/.config/waybar"
    mkdir -p "$config_dir"
    
    cat > "$config_dir/config" << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 35,
    "spacing": 10,
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": ["cpu", "memory", "disk", "network", "bluetooth", "tray", "custom/power"],
    
    "hyprland/workspaces": {
        "format": "{icon}",
        "format-icons": {
            "1": "󰲠",
            "2": "󰖟",
            "3": "󰉋",
            "4": "󰨞",
            "5": "󰧮",
            "6": "󰍹",
            "7": "󰮂",
            "8": "󰧑",
            "9": "󰎈",
            "10": "󰍺"
        },
        "persistent_workspaces": {
            "1": [],
            "2": [],
            "3": [],
            "4": [],
            "5": [],
            "6": [],
            "7": [],
            "8": [],
            "9": [],
            "10": []
        }
    },
    
    "hyprland/window": {
        "format": "{}",
        "max-length": 50
    },
    
    "clock": {
        "format": "{:%H:%M %a %d %b}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    },
    
    "cpu": {
        "format": "󰍛 {usage}%",
        "tooltip": true,
        "interval": 2
    },
    
    "memory": {
        "format": "󰘚 {percentage}%",
        "tooltip-format": "RAM: {used:0.1f}G/{total:0.1f}G"
    },
    
    "disk": {
        "format": "󰋊 {percentage_used}%",
        "path": "/",
        "tooltip-format": "Used: {used} / Total: {total}"
    },
    
    "network": {
        "format-wifi": "󰤨 {signalStrength}%",
        "format-ethernet": "󰈁 Connected",
        "format-disconnected": "󰤭 Disconnected",
        "tooltip-format-wifi": "SSID: {essid}\nIP: {ipaddr}",
        "tooltip-format-ethernet": "Interface: {ifname}\nIP: {ipaddr}"
    },
    
    "bluetooth": {
        "format": "󰂯",
        "format-disabled": "󰂲",
        "format-off": "󰂲",
        "tooltip-format": "{status}"
    },
    
    "tray": {
        "spacing": 10
    },
    
    "custom/power": {
        "format": "󰐥",
        "tooltip": "Power Menu",
        "on-click": "wlogout"
    }
}
EOF

    cat > "$config_dir/style.css" << 'EOF'
/* Summer Night Waybar Theme */
* {
    font-family: 'JetBrains Mono', monospace;
    font-size: 13px;
    font-weight: 500;
}

window#waybar {
    background: linear-gradient(135deg, rgba(26, 32, 44, 0.9) 0%, rgba(45, 55, 72, 0.9) 100%);
    color: #e2e8f0;
    border-radius: 0px 0px 12px 12px;
    border: 2px solid rgba(255, 107, 107, 0.3);
    border-top: none;
}

#workspaces {
    background: rgba(255, 107, 107, 0.1);
    border-radius: 8px;
    padding: 2px 8px;
    margin: 4px;
}

#workspaces button {
    color: #cbd5e0;
    border-radius: 6px;
    padding: 2px 8px;
    margin: 0 2px;
    background: transparent;
    border: none;
    transition: all 0.3s ease;
}

#workspaces button:hover {
    background: rgba(78, 205, 196, 0.2);
    color: #4ecdc4;
}

#workspaces button.active {
    background: linear-gradient(45deg, #ff6b6b, #4ecdc4);
    color: #1a202c;
    font-weight: bold;
}

#window {
    color: #a0aec0;
    font-style: italic;
}

#clock {
    background: linear-gradient(45deg, rgba(78, 205, 196, 0.2), rgba(255, 107, 107, 0.2));
    color: #e2e8f0;
    border-radius: 8px;
    padding: 4px 12px;
    font-weight: bold;
}

#cpu, #memory, #disk, #network, #bluetooth {
    background: rgba(45, 55, 72, 0.6);
    border-radius: 6px;
    padding: 4px 8px;
    margin: 0 2px;
    color: #cbd5e0;
    border: 1px solid rgba(78, 205, 196, 0.3);
}

#cpu {
    color: #ff6b6b;
}

#memory {
    color: #4ecdc4;
}

#disk {
    color: #ffa726;
}

#network {
    color: #66bb6a;
}

#bluetooth {
    color: #7986cb;
}

#tray {
    background: rgba(45, 55, 72, 0.6);
    border-radius: 6px;
    padding: 2px 6px;
}

#custom-power {
    background: linear-gradient(45deg, #ff6b6b, #ff5722);
    color: white;
    border-radius: 6px;
    padding: 4px 8px;
    margin-left: 4px;
    font-size: 14px;
}

#custom-power:hover {
    background: linear-gradient(45deg, #ff5722, #ff6b6b);
}
EOF
}

create_rofi_config() {
    local config_dir="$HOME/.config/rofi"
    mkdir -p "$config_dir"
    
    cat > "$config_dir/summer-night.rasi" << 'EOF'
/* Summer Night Rofi Theme */
* {
    background-color: transparent;
    text-color: #e2e8f0;
    font: "JetBrains Mono 12";
}

window {
    background-color: rgba(26, 32, 44, 0.95);
    border: 2px solid;
    border-color: rgba(255, 107, 107, 0.5);
    border-radius: 12px;
    padding: 20px;
    width: 600px;
}

mainbox {
    children: [inputbar, listview];
    spacing: 20px;
}

inputbar {
    background-color: rgba(45, 55, 72, 0.8);
    border-radius: 8px;
    padding: 12px;
    border: 1px solid rgba(78, 205, 196, 0.3);
}

prompt {
    text-color: #4ecdc4;
    font-weight: bold;
}

entry {
    placeholder: "Search applications...";
    placeholder-color: #718096;
    text-color: #e2e8f0;
}

listview {
    lines: 8;
    scrollbar: false;
}

element {
    padding: 8px 12px;
    border-radius: 6px;
    spacing: 8px;
}

element selected {
    background-color: linear-gradient(45deg, rgba(255, 107, 107, 0.3), rgba(78, 205, 196, 0.3));
    text-color: #ffffff;
}

element-icon {
    size: 24px;
}

element-text {
    vertical-align: 0.5;
}
EOF
}

create_wlogout_config() {
    local config_dir="$HOME/.config/wlogout"
    mkdir -p "$config_dir"
    
    cat > "$config_dir/layout" << 'EOF'
{
    "label" : "lock",
    "action" : "swaylock-effects --screenshots --clock --indicator --effect-blur 7x5",
    "text" : "Lock",
    "keybind" : "l"
}
{
    "label" : "hibernate",
    "action" : "systemctl hibernate",
    "text" : "Hibernate",
    "keybind" : "h"
}
{
    "label" : "logout",
    "action" : "hyprctl dispatch exit 0",
    "text" : "Logout",
    "keybind" : "e"
}
{
    "label" : "shutdown",
    "action" : "systemctl poweroff",
    "text" : "Shutdown",
    "keybind" : "s"
}
{
    "label" : "suspend",
    "action" : "systemctl suspend",
    "text" : "Suspend",
    "keybind" : "u"
}
{
    "label" : "reboot",
    "action" : "systemctl reboot",
    "text" : "Reboot",
    "keybind" : "r"
}
EOF

    cat > "$config_dir/style.css" << 'EOF'
/* Summer Night wlogout theme */
* {
    background-image: none;
    font-family: "JetBrains Mono";
}

window {
    background: rgba(26, 32, 44, 0.9);
}

button {
    background: linear-gradient(45deg, rgba(45, 55, 72, 0.8), rgba(26, 32, 44, 0.8));
    border: 2px solid rgba(255, 107, 107, 0.3);
    border-radius: 12px;
    color: #e2e8f0;
    font-size: 16px;
    margin: 10px;
    padding: 20px;
    transition: all 0.3s ease;
}

button:hover {
    background: linear-gradient(45deg, rgba(255, 107, 107, 0.4), rgba(78, 205, 196, 0.4));
    border-color: rgba(78, 205, 196, 0.6);
    color: #ffffff;
    transform: scale(1.05);
}

button:focus {
    background: linear-gradient(45deg, rgba(255, 107, 107, 0.6), rgba(78, 205, 196, 0.6));
    color: #ffffff;
}
EOF
}

setup_swayidle() {
    # Install swayidle if not present
    if ! pacman -Qi swayidle &>/dev/null; then
        pacman -S --noconfirm swayidle
    fi
    
    # Already configured in hyprland.conf exec-once
    echo "Swayidle configured for auto-lock after 5 minutes"
}

download_wallpaper() {
    local wallpaper_dir="$HOME/Pictures"
    mkdir -p "$wallpaper_dir"
    
    # Create a summer night gradient wallpaper using ImageMagick
    if command -v convert &>/dev/null; then
        convert -size 2560x1440 gradient:'#1a202c-#2d3748' "$wallpaper_dir/wallpaper.jpg"
    else
        pacman -S --noconfirm imagemagick
        convert -size 2560x1440 gradient:'#1a202c-#2d3748' "$wallpaper_dir/wallpaper.jpg"
    fi
    
    echo "Summer night wallpaper created"
}

setup_user_config() {
    local target_user="${1:-$USER}"
    local user_home
    
    if [[ "$target_user" == "root" ]]; then
        user_home="/root"
    else
        user_home="/home/$target_user"
    fi
    
    # Switch to target user for config creation
    if [[ $EUID -eq 0 && "$target_user" != "root" ]]; then
        sudo -u "$target_user" bash << EOF
export HOME="$user_home"
cd "\$HOME"
$(declare -f create_hyprland_config create_waybar_config create_rofi_config create_wlogout_config download_wallpaper)
create_hyprland_config
create_waybar_config  
create_rofi_config
create_wlogout_config
download_wallpaper
EOF
    else
        export HOME="$user_home"
        cd "$HOME"
        create_hyprland_config
        create_waybar_config
        create_rofi_config
        create_wlogout_config
        download_wallpaper
    fi
}

main() {
    echo "=== Hyprland Summer Night Setup ==="
    
    # Get target user
    if [[ $EUID -eq 0 ]]; then
        read -p "Setup Hyprland for which user? " TARGET_USER
        if ! id "$TARGET_USER" &>/dev/null; then
            echo "User $TARGET_USER not found"
            exit 1
        fi
    else
        TARGET_USER="$USER"
    fi
    
    echo "Installing Hyprland environment for user: $TARGET_USER"
    
    install_yay_if_needed
    install_hyprland_core
    setup_swayidle
    setup_user_config "$TARGET_USER"
    
    echo "Hyprland setup complete!"
    echo ""
    echo "Summer Night Theme Features:"
    echo "- Vim-like navigation (hjkl)"
    echo "- Super+Enter: Terminal"
    echo "- Super+D: App launcher" 
    echo "- Super+Escape: Lock screen"
    echo "- Super+Pause: Power menu"
    echo "- Super+M/N: Move workspace between monitors"
    echo "- Print Screen: Screenshot"
    echo "- Auto-lock after 5 minutes"
    echo ""
    echo "Logout and select Hyprland from your display manager"
}

# Allow running as standalone script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi