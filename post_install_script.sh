#!/bin/bash
set -e

# Desktop environments
declare -A desktops=(
    [1]="GNOME (full)"
    [2]="KDE Plasma (full)"
    [skip]="Skip desktop installation"
)

print_desktops() {
    echo "Desktop environments:"
    for key in "${!desktops[@]}"; do
        echo "  $key) ${desktops[$key]}"
    done
}

get_desktop_choice() {
    print_desktops
    read -p "Choose desktop [1/2/skip]: " DESKTOP_CHOICE
    
    if [[ "$DESKTOP_CHOICE" != "1" && "$DESKTOP_CHOICE" != "2" && "$DESKTOP_CHOICE" != "skip" ]]; then
        echo "Invalid choice"
        exit 1
    fi
}

setup_locale() {
    echo "Setting up locale..."
    
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

setup_keyboard() {
    echo "Setting US keyboard layout..."
    localectl set-keymap us
    localectl set-x11-keymap us
}

install_fonts() {
    echo "Installing comprehensive font packages..."
    
    # Base fonts
    pacman -S --noconfirm \
        ttf-dejavu ttf-liberation noto-fonts noto-fonts-emoji \
        ttf-roboto ttf-opensans adobe-source-code-pro-fonts
    
    # International fonts
    pacman -S --noconfirm \
        noto-fonts-cjk noto-fonts-extra \
        ttf-indic-otf ttf-tibetan-machine
    
    # MS fonts equivalent
    if ! pacman -Qi ttf-ms-fonts &>/dev/null; then
        echo "Installing MS fonts from AUR..."
        install_aur_package ttf-ms-fonts
    fi
}

install_aur_package() {
    local package="$1"
    local temp_dir="/tmp/aur_$package"
    
    # Create temporary user for AUR if running as root
    if [[ $EUID -eq 0 ]]; then
        if ! id -u auruser &>/dev/null; then
            useradd -r -s /bin/bash auruser
            mkdir -p /home/auruser
            chown auruser:auruser /home/auruser
        fi
        
        sudo -u auruser bash << EOF
cd /tmp
git clone https://aur.archlinux.org/$package.git $temp_dir
cd $temp_dir
makepkg -si --noconfirm
EOF
    else
        cd /tmp
        git clone https://aur.archlinux.org/$package.git $temp_dir
        cd $temp_dir
        makepkg -si --noconfirm
    fi
    
    rm -rf $temp_dir
}

install_gnome() {
    echo "Installing GNOME desktop..."
    
    pacman -S --noconfirm \
        gnome gnome-extra gdm \
        firefox nautilus-sendto \
        file-roller evince
    
    systemctl enable gdm
    echo "GNOME installed"
}

install_kde() {
    echo "Installing KDE Plasma desktop..."
    
    pacman -S --noconfirm \
        plasma-meta kde-applications-meta sddm \
        firefox konsole dolphin kate gwenview \
        okular spectacle ark
    
    systemctl enable sddm
    echo "KDE Plasma installed"
}

install_desktop() {
    case "$DESKTOP_CHOICE" in
        "1")
            install_gnome
            ;;
        "2")
            install_kde
            ;;
        "skip")
            echo "Skipping desktop installation"
            ;;
    esac
}

update_system() {
    echo "Updating package database..."
    pacman -Sy
}

main() {
    echo "=== Arch Linux Post-Install Setup ==="
    
    # Check if running on installed system vs chroot
    if [[ -f /.dockerenv ]] || [[ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]]; then
        echo "Running in chroot environment"
        IN_CHROOT=true
    else
        echo "Running on installed system"
        IN_CHROOT=false
    fi
    
    get_desktop_choice
    update_system
    setup_locale
    
    # Skip hardware-specific configs in chroot
    if [[ "$IN_CHROOT" == false ]]; then
        setup_timezone
        setup_keyboard
    fi
    
    install_fonts
    install_desktop
    
    echo "Post-install setup complete!"
    
    if [[ "$DESKTOP_CHOICE" != "skip" ]]; then
        echo "Reboot to start the desktop environment"
    fi
}

# Allow running as standalone script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi