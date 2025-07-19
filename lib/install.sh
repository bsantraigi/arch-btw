#!/bin/bash

# Base installation functions extracted from install.sh

install_base_system() {
    echo "Installing base system..."
    pacstrap /mnt base base-devel linux linux-firmware lvm2 cryptsetup grub efibootmgr networkmanager sudo vim git timeshift
    genfstab -U /mnt >> /mnt/etc/fstab
}

configure_base_system() {
    local username="$1"
    local user_pass="$2"
    local luks_uuid="$3"
    
    echo "Configuring base system..."
    
    # Generate crypttab
    echo "cryptlvm UUID=$luks_uuid none luks" > /mnt/etc/crypttab
    
    # Configure chroot script
    cat > /mnt/root/configure.sh << 'EOF'
#!/bin/bash
set -e

# Timezone and locale
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname
echo "archbox" > /etc/hostname
cat > /etc/hosts << 'HOSTS'
127.0.0.1	localhost
::1		localhost
127.0.1.1	archbox.localdomain	archbox
HOSTS

# Root password
echo "root:rootpass" | chpasswd

# Create user
useradd -m -G wheel -s /bin/bash "$1"
echo "$1:$2" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Configure mkinitcpio for encryption
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -p linux

# Configure GRUB
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
LUKS_UUID="$3"
sed -i "s/^GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$LUKS_UUID:cryptlvm root=\/dev\/SysVG\/root\"/" /etc/default/grub

# Install and configure GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable services
systemctl enable NetworkManager

echo "Base configuration complete!"
EOF

    chmod +x /mnt/root/configure.sh
    arch-chroot /mnt /root/configure.sh "$username" "$user_pass" "$luks_uuid"
    rm /mnt/root/configure.sh
}

run_post_install() {
    local run_hyprland="$1"
    
    if [[ "$run_hyprland" == "y" && -f "post_install_script.sh" ]]; then
        echo "Copying post-install script..."
        cp post_install_script.sh /mnt/root/
        chmod +x /mnt/root/post_install_script.sh
        
        echo "Running post-install setup in chroot..."
        arch-chroot /mnt /root/post_install_script.sh
        rm /mnt/root/post_install_script.sh
    fi
}

# Full installation orchestrator
run_full_installation() {
    local disk="$1"
    local scheme="$2" 
    local username="$3"
    local crypt_pass="$4"
    local user_pass="$5"
    local run_hyprland="${6:-n}"
    
    # Set global variables for partition functions
    DISK="$disk"
    SCHEME="$scheme"
    USERNAME="$username"
    CRYPT_PASS="$crypt_pass"
    USER_PASS="$user_pass"
    
    print_step "Starting full installation process..."
    
    # Partitioning phase
    print_info "Phase 1: Disk setup and partitioning"
    wipe_disk
    create_partitions
    setup_encryption
    setup_lvm
    format_partitions
    mount_system
    
    # Installation phase
    print_info "Phase 2: Base system installation"
    install_base_system
    
    # Configuration phase
    print_info "Phase 3: System configuration"
    local luks_uuid=$(blkid -s UUID -o value "$LVM_PART")
    configure_base_system "$username" "$user_pass" "$luks_uuid"
    
    # Post-install phase
    if [[ "$run_hyprland" == "y" ]]; then
        print_info "Phase 4: Hyprland setup"
        run_post_install "$run_hyprland"
    fi
    
    print_success "Installation completed successfully!"
    return 0
}
