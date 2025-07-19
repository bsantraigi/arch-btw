#!/bin/bash

# Main setup script - Arch Linux Personal Setup Tool
# Entry point for the menu-driven system setup

set -e

# Script directory and library imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/state.sh"
source "$SCRIPT_DIR/lib/partitions.sh"
source "$SCRIPT_DIR/lib/install.sh"
source "$SCRIPT_DIR/lib/hyprland.sh"

# Global variables
SCRIPT_MOUNTED=false

# Display main menu
show_main_menu() {
    clear
    local current_state=$(detect_system_state)
    local current_disk=$(get_current_disk)
    local state_desc=$(get_state_description "$current_state")
    
    print_header "Arch Linux Personal Setup Tool"
    echo
    echo -e "System Status: ${YELLOW}$current_state${NC}"
    echo -e "Description:   $state_desc"
    echo -e "Current Disk:  $current_disk"
    echo
    echo "Operations:"
    echo "  1) Setup/Recreate LUKS + Partition + LVM"
    echo "  2) Unmount Configuration"
    echo "  3) Remount Configuration"
    echo "  4) Install Base OS + Software"
    echo "  5) Install Hyprland + Essential Tools"
    echo "  6) Deploy Dotfiles"
    echo "  7) Setup VirtualBox + Root Access"
    echo "  8) Setup Timeshift Backups"
    echo "  9) Configure Workspace Defaults"
    echo " 10) System Status & Info"
    echo " 11) Exit"
    echo
}

# Get user menu choice
get_menu_choice() {
    local choice
    while true; do
        read -p "Choice [1-11]: " choice
        case "$choice" in
            [1-9]|1[01])
                echo "$choice"
                return 0
                ;;
            *)
                print_error "Invalid choice. Please select 1-11."
                ;;
        esac
    done
}

# Operation placeholders - will be implemented in later phases
op_setup_partitions() {
    print_step "Setup/Recreate LUKS + Partition + LVM"
    
    if ! validate_state_for_operation "setup_partitions" "$(detect_system_state)"; then
        return 1
    fi
    
    print_warning "This operation will DESTROY all data on the selected disk!"
    echo
    show_available_disks
    echo
    
    if ! confirm_operation "Continue with partitioning?"; then
        print_info "Operation cancelled"
        return 0
    fi
    
    # Get partitioning parameters
    if ! get_partition_input; then
        print_error "Invalid input parameters"
        return 1
    fi
    
    print_info "Starting partitioning process..."
    log_operation "Partitioning disk $DISK with scheme $SCHEME"
    
    # Execute partitioning
    if wipe_disk && create_partitions && setup_encryption && setup_lvm && format_partitions && mount_system; then
        SCRIPT_MOUNTED=true
        print_success "Partitioning completed successfully!"
        print_info "System is now mounted at /mnt and ready for base installation"
    else
        print_error "Partitioning failed"
        return 1
    fi
}

op_unmount_system() {
    print_step "Unmount Configuration"
    
    if ! validate_state_for_operation "unmount_system" "$(detect_system_state)"; then
        return 1
    fi
    
    if confirm_operation "Unmount all filesystems and close LUKS?"; then
        unmount_system
        cryptsetup close cryptlvm 2>/dev/null || true
        print_success "System unmounted successfully"
        SCRIPT_MOUNTED=false
    else
        print_info "Operation cancelled"
    fi
}

op_remount_system() {
    print_step "Remount Configuration"
    
    if ! validate_state_for_operation "remount_system" "$(detect_system_state)"; then
        return 1
    fi
    
    # Find the LUKS partition
    local luks_part
    for part in /dev/sd[a-z][0-9] /dev/nvme[0-9]n[0-9]p[0-9]; do
        if [[ -b "$part" ]] && cryptsetup isLuks "$part" 2>/dev/null; then
            luks_part="$part"
            break
        fi
    done
    
    if [[ -z "$luks_part" ]]; then
        print_error "No LUKS partition found"
        return 1
    fi
    
    print_info "Found LUKS partition: $luks_part"
    
    # Get encryption password
    local crypt_pass
    crypt_pass=$(get_confirmed_password "Encryption password")
    
    print_info "Remounting system..."
    if remount_existing_system "$luks_part" "$crypt_pass"; then
        SCRIPT_MOUNTED=true
        print_success "System remounted successfully"
        print_info "Filesystems are now available at /mnt"
    else
        print_error "Failed to remount system"
        return 1
    fi
}

op_install_base() {
    print_step "Install Base OS + Software"
    
    if ! validate_state_for_operation "install_base" "$(detect_system_state)"; then
        return 1
    fi
    
    # Check if we have the required variables from partitioning
    if [[ -z "$USERNAME" || -z "$USER_PASS" || -z "$LVM_PART" ]]; then
        print_warning "Missing installation parameters from previous partitioning"
        print_info "This usually means the system was partitioned in a previous session"
        
        # Get required parameters
        read -p "Admin username: " USERNAME
        USER_PASS=$(get_confirmed_password "User password")
        
        # Find LVM partition
        local luks_device
        if luks_device=$(cryptsetup status cryptlvm 2>/dev/null | grep device: | awk '{print $2}'); then
            LVM_PART="$luks_device"
        else
            print_error "Cannot determine LUKS partition"
            return 1
        fi
    fi
    
    if ! confirm_operation "Install base system for user '$USERNAME'?"; then
        print_info "Operation cancelled"
        return 0
    fi
    
    print_info "Installing base system..."
    log_operation "Installing base system for user $USERNAME"
    
    # Get LUKS UUID for bootloader configuration
    local luks_uuid=$(blkid -s UUID -o value "$LVM_PART")
    
    if install_base_system && configure_base_system "$USERNAME" "$USER_PASS" "$luks_uuid"; then
        print_success "Base system installation completed!"
        print_info "System is ready for Hyprland installation or can be rebooted"
    else
        print_error "Base system installation failed"
        return 1
    fi
}

op_install_hyprland() {
    print_step "Install Hyprland + Essential Tools"
    
    if ! validate_state_for_operation "install_hyprland" "$(detect_system_state)"; then
        return 1
    fi
    
    # Check if we're in chroot or installed system
    local in_chroot=false
    if [[ -f /mnt/etc/hostname ]]; then
        print_info "Detected installed system - will run in chroot"
        in_chroot=true
    fi
    
    if ! confirm_operation "Install Hyprland desktop environment?"; then
        print_info "Operation cancelled"
        return 0
    fi
    
    print_info "Installing Hyprland environment..."
    log_operation "Installing Hyprland desktop environment"
    
    if [[ "$in_chroot" == true ]]; then
        # Running from live environment, install into /mnt
        print_info "Installing Hyprland in chroot environment..."
        
        # Copy post-install script to chroot
        cp "$SCRIPT_DIR/post_install_script.sh" /mnt/root/
        chmod +x /mnt/root/post_install_script.sh
        
        # Run in chroot
        if arch-chroot /mnt /root/post_install_script.sh; then
            rm /mnt/root/post_install_script.sh
            print_success "Hyprland installation completed!"
            print_info "System is ready to reboot into Hyprland"
        else
            print_error "Hyprland installation failed"
            return 1
        fi
    else
        # Running on installed system
        print_info "Installing Hyprland on live system..."
        
        # Find the target user
        local target_user
        if [[ $EUID -eq 0 ]]; then
            target_user=$(awk -F: '$3 >= 1000 && $3 < 65534 && $6 ~ /^\/home/ {print $1; exit}' /etc/passwd)
            if [[ -z "$target_user" ]]; then
                print_error "Could not find target user"
                return 1
            fi
        else
            target_user="$USER"
        fi
        
        if install_hyprland_environment "$target_user"; then
            print_success "Hyprland installation completed!"
            print_info "Log out and select Hyprland from the display manager"
        else
            print_error "Hyprland installation failed"
            return 1
        fi
    fi
}

op_deploy_dotfiles() {
    print_step "Deploy Dotfiles"
    
    if ! validate_state_for_operation "deploy_dotfiles" "$(detect_system_state)"; then
        return 1
    fi
    
    # Check if we're in chroot or installed system
    local in_chroot=false
    local dotfiles_path="/home"
    
    if [[ -f /mnt/etc/hostname ]]; then
        print_info "Detected installed system - will deploy in chroot"
        in_chroot=true
        dotfiles_path="/mnt/home"
    fi
    
    # Find target user
    local target_user
    if [[ "$in_chroot" == true ]]; then
        target_user=$(awk -F: '$3 >= 1000 && $3 < 65534 && $6 ~ /^\/home/ {print $1}' /mnt/etc/passwd | head -1)
    else
        if [[ $EUID -eq 0 ]]; then
            target_user=$(awk -F: '$3 >= 1000 && $3 < 65534 && $6 ~ /^\/home/ {print $1; exit}' /etc/passwd)
        else
            target_user="$USER"
        fi
    fi
    
    if [[ -z "$target_user" ]]; then
        print_error "Could not find target user"
        return 1
    fi
    
    local dotfiles_installer="$dotfiles_path/$target_user/dotfiles/dotfiles-install.sh"
    
    if [[ ! -f "$dotfiles_installer" ]]; then
        print_error "Dotfiles installer not found at $dotfiles_installer"
        print_info "Please ensure dotfiles are cloned to ~/dotfiles/"
        return 1
    fi
    
    if ! confirm_operation "Deploy dotfiles for user '$target_user'?"; then
        print_info "Operation cancelled"
        return 0
    fi
    
    print_info "Deploying dotfiles..."
    log_operation "Deploying dotfiles for user $target_user"
    
    if [[ "$in_chroot" == true ]]; then
        # Deploy in chroot environment
        arch-chroot /mnt bash -c "cd /home/$target_user/dotfiles && chmod +x dotfiles-install.sh && sudo -u $target_user ./dotfiles-install.sh install-no-backup"
    else
        # Deploy on live system
        cd "$dotfiles_path/$target_user/dotfiles"
        chmod +x dotfiles-install.sh
        if [[ $EUID -eq 0 ]]; then
            sudo -u "$target_user" ./dotfiles-install.sh install-no-backup
        else
            ./dotfiles-install.sh install-no-backup
        fi
    fi
    
    if [[ $? -eq 0 ]]; then
        print_success "Dotfiles deployment completed!"
        print_info "Configuration files are now installed"
        print_info "Log out and log back in for all changes to take effect"
    else
        print_error "Dotfiles deployment failed"
        return 1
    fi
}

op_setup_virtualbox() {
    print_step "Setup VirtualBox + Root Access"
    
    if ! validate_state_for_operation "setup_virtualbox" "$(detect_system_state)"; then
        return 1
    fi
    
    # Check if we're in chroot or installed system
    local in_chroot=false
    local target_prefix=""
    
    if [[ -f /mnt/etc/hostname ]]; then
        print_info "Detected installed system - will setup in chroot"
        in_chroot=true
        target_prefix="/mnt"
    fi
    
    if ! confirm_operation "Setup VirtualBox with root access integration?"; then
        print_info "Operation cancelled"
        return 0
    fi
    
    print_info "Installing VirtualBox and configuring root access..."
    log_operation "Setting up VirtualBox with root access"
    
    if [[ "$in_chroot" == true ]]; then
        # Install in chroot environment
        print_info "Installing VirtualBox packages in chroot..."
        
        # Install VirtualBox
        arch-chroot /mnt pacman -S --noconfirm virtualbox virtualbox-host-modules-arch
        
        # Add user to vboxusers group
        local target_user=$(awk -F: '$3 >= 1000 && $3 < 65534 && $6 ~ /^\/home/ {print $1}' /mnt/etc/passwd | head -1)
        if [[ -n "$target_user" ]]; then
            arch-chroot /mnt usermod -aG vboxusers "$target_user"
            print_success "Added $target_user to vboxusers group"
        fi
        
        # Enable VirtualBox kernel modules
        arch-chroot /mnt bash -c "echo 'vboxdrv' >> /etc/modules-load.d/virtualbox.conf"
        arch-chroot /mnt bash -c "echo 'vboxnetflt' >> /etc/modules-load.d/virtualbox.conf"
        arch-chroot /mnt bash -c "echo 'vboxnetadp' >> /etc/modules-load.d/virtualbox.conf"
        
    else
        # Install on live system
        print_info "Installing VirtualBox packages..."
        
        # Install VirtualBox
        pacman -S --noconfirm virtualbox virtualbox-host-modules-arch
        
        # Add current user to vboxusers group
        local target_user="$USER"
        if [[ $EUID -eq 0 ]]; then
            target_user=$(awk -F: '$3 >= 1000 && $3 < 65534 && $6 ~ /^\/home/ {print $1; exit}' /etc/passwd)
        fi
        
        if [[ -n "$target_user" ]]; then
            usermod -aG vboxusers "$target_user"
            print_success "Added $target_user to vboxusers group"
        fi
        
        # Load VirtualBox kernel modules
        modprobe vboxdrv vboxnetflt vboxnetadp
        
        # Enable VirtualBox kernel modules
        echo 'vboxdrv' >> /etc/modules-load.d/virtualbox.conf
        echo 'vboxnetflt' >> /etc/modules-load.d/virtualbox.conf
        echo 'vboxnetadp' >> /etc/modules-load.d/virtualbox.conf
    fi
    
    print_success "VirtualBox installation completed!"
    print_info "Root access integration is available via the VirtualBox Root desktop entry"
    print_info "Reboot required to load VirtualBox kernel modules"
}

op_setup_timeshift() {
    print_step "Setup Timeshift Backups"
    
    if ! validate_state_for_operation "setup_timeshift" "$(detect_system_state)"; then
        return 1
    fi
    
    # Check if we're in chroot or installed system
    local in_chroot=false
    
    if [[ -f /mnt/etc/hostname ]]; then
        print_info "Detected installed system - will setup in chroot"
        in_chroot=true
    fi
    
    if ! confirm_operation "Setup Timeshift backup system?"; then
        print_info "Operation cancelled"
        return 0
    fi
    
    print_info "Installing and configuring Timeshift..."
    log_operation "Setting up Timeshift backup system"
    
    if [[ "$in_chroot" == true ]]; then
        # Install in chroot environment
        print_info "Installing Timeshift in chroot..."
        arch-chroot /mnt pacman -S --noconfirm timeshift
        
        # Check if timeshift partition exists
        if lvs 2>/dev/null | grep -q timeshift; then
            print_info "Timeshift LVM partition detected"
            
            # Create timeshift mount directory
            arch-chroot /mnt mkdir -p /timeshift
            
            # Add to fstab
            local timeshift_uuid=$(arch-chroot /mnt blkid -s UUID -o value /dev/vgcrypt/timeshift)
            if [[ -n "$timeshift_uuid" ]]; then
                echo "UUID=$timeshift_uuid /timeshift ext4 defaults 0 2" >> /mnt/etc/fstab
                print_success "Added Timeshift partition to fstab"
            fi
            
            # Mount timeshift partition
            arch-chroot /mnt mount /timeshift
            
        else
            print_warning "No dedicated Timeshift partition found"
            print_info "Timeshift will use available space on root partition"
        fi
        
    else
        # Install on live system
        print_info "Installing Timeshift..."
        pacman -S --noconfirm timeshift
        
        # Check if timeshift partition exists and mount it
        if lvs 2>/dev/null | grep -q timeshift; then
            print_info "Timeshift LVM partition detected"
            mkdir -p /timeshift
            mount /dev/vgcrypt/timeshift /timeshift
        fi
    fi
    
    print_success "Timeshift installation completed!"
    print_info "Configure Timeshift with: sudo timeshift-gtk"
    print_info "Recommended: Set up automatic daily snapshots"
    if lvs 2>/dev/null | grep -q timeshift; then
        print_info "Dedicated Timeshift partition is available for snapshots"
    fi
}

op_configure_workspace() {
    print_step "Configure Workspace Defaults"
    
    if ! validate_state_for_operation "configure_workspace" "$(detect_system_state)"; then
        return 1
    fi
    
    # Check if we're in chroot or installed system
    local in_chroot=false
    local config_path="/home"
    
    if [[ -f /mnt/etc/hostname ]]; then
        print_info "Detected installed system - will configure in chroot"
        in_chroot=true
        config_path="/mnt/home"
    fi
    
    # Find target user
    local target_user
    if [[ "$in_chroot" == true ]]; then
        target_user=$(awk -F: '$3 >= 1000 && $3 < 65534 && $6 ~ /^\/home/ {print $1}' /mnt/etc/passwd | head -1)
    else
        if [[ $EUID -eq 0 ]]; then
            target_user=$(awk -F: '$3 >= 1000 && $3 < 65534 && $6 ~ /^\/home/ {print $1; exit}' /etc/passwd)
        else
            target_user="$USER"
        fi
    fi
    
    if [[ -z "$target_user" ]]; then
        print_error "Could not find target user"
        return 1
    fi
    
    if ! confirm_operation "Configure workspace defaults for user '$target_user'?"; then
        print_info "Operation cancelled"
        return 0
    fi
    
    print_info "Configuring workspace defaults..."
    log_operation "Configuring workspace defaults for user $target_user"
    
    # Create workspace configuration script
    local workspace_script="$config_path/$target_user/.config/hypr/workspace-setup.sh"
    
    if [[ "$in_chroot" == true ]]; then
        # Configure in chroot
        arch-chroot /mnt mkdir -p "/home/$target_user/.config/hypr"
        arch-chroot /mnt bash -c "cat > /home/$target_user/.config/hypr/workspace-setup.sh" << 'EOF'
#!/bin/bash
# Workspace default applications setup

# Wait for Hyprland to be ready
sleep 2

# Launch default applications
hyprctl dispatch workspace 1
kitty &
sleep 1

hyprctl dispatch workspace 2
microsoft-edge-stable &
sleep 2

# Return to workspace 1
hyprctl dispatch workspace 1

# Focus on terminal
hyprctl dispatch focuswindow "kitty"
EOF
        
        arch-chroot /mnt chmod +x "/home/$target_user/.config/hypr/workspace-setup.sh"
        arch-chroot /mnt chown "$target_user:$target_user" "/home/$target_user/.config/hypr/workspace-setup.sh"
        
        # Add to Hyprland autostart
        local hypr_config="/mnt/home/$target_user/.config/hypr/hyprland.conf"
        if [[ -f "$hypr_config" ]]; then
            echo "" >> "$hypr_config"
            echo "# Workspace defaults" >> "$hypr_config"
            echo "exec-once = ~/.config/hypr/workspace-setup.sh" >> "$hypr_config"
            print_success "Added workspace setup to Hyprland autostart"
        fi
        
    else
        # Configure on live system
        mkdir -p "$config_path/$target_user/.config/hypr"
        
        cat > "$workspace_script" << 'EOF'
#!/bin/bash
# Workspace default applications setup

# Wait for Hyprland to be ready
sleep 2

# Launch default applications
hyprctl dispatch workspace 1
kitty &
sleep 1

hyprctl dispatch workspace 2
microsoft-edge-stable &
sleep 2

# Return to workspace 1
hyprctl dispatch workspace 1

# Focus on terminal
hyprctl dispatch focuswindow "kitty"
EOF
        
        chmod +x "$workspace_script"
        
        if [[ $EUID -eq 0 ]]; then
            chown "$target_user:$target_user" "$workspace_script"
        fi
        
        # Add to Hyprland autostart
        local hypr_config="$config_path/$target_user/.config/hypr/hyprland.conf"
        if [[ -f "$hypr_config" ]]; then
            echo "" >> "$hypr_config"
            echo "# Workspace defaults" >> "$hypr_config"
            echo "exec-once = ~/.config/hypr/workspace-setup.sh" >> "$hypr_config"
            print_success "Added workspace setup to Hyprland autostart"
        fi
    fi
    
    print_success "Workspace configuration completed!"
    print_info "Default layout: Workspace 1 (Terminal), Workspace 2 (Browser)"
    print_info "Applications will auto-launch when Hyprland starts"
}

op_system_info() {
    print_step "System Status & Info"
    
    local current_state=$(detect_system_state)
    local current_disk=$(get_current_disk)
    local state_desc=$(get_state_description "$current_state")
    
    echo
    print_info "=== System Information ==="
    echo "State: $current_state"
    echo "Description: $state_desc"
    echo "Disk: $current_disk"
    echo
    
    if [[ "$current_state" == "MOUNTED" || "$current_state" == "INSTALLED" ]]; then
        print_info "=== Mount Points ==="
        df -h /mnt* 2>/dev/null || echo "No mount points found"
        echo
        
        print_info "=== LVM Information ==="
        lvs 2>/dev/null || echo "No LVM volumes found"
        echo
    fi
    
    if [[ "$current_state" != "CLEAN" ]]; then
        print_info "=== LUKS Information ==="
        cryptsetup status cryptlvm 2>/dev/null || echo "No LUKS device found"
        echo
    fi
    
    print_info "=== Available Disks ==="
    show_available_disks
}

# Main program loop
main() {
    # Setup
    setup_cleanup_trap
    check_root
    check_arch_live
    
    log_operation "Setup script started"
    
    while true; do
        show_main_menu
        choice=$(get_menu_choice)
        
        echo
        log_operation "User selected option $choice"
        
        case "$choice" in
            1)
                op_setup_partitions
                ;;
            2)
                op_unmount_system
                ;;
            3)
                op_remount_system
                ;;
            4)
                op_install_base
                ;;
            5)
                op_install_hyprland
                ;;
            6)
                op_deploy_dotfiles
                ;;
            7)
                op_setup_virtualbox
                ;;
            8)
                op_setup_timeshift
                ;;
            9)
                op_configure_workspace
                ;;
            10)
                op_system_info
                ;;
            11)
                print_info "Exiting setup tool"
                log_operation "Setup script exited normally"
                exit 0
                ;;
        esac
        
        echo
        press_enter_to_continue
    done
}

# Run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
