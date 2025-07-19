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
    echo "  7) System Status & Info"
    echo "  8) Exit"
    echo
}

# Get user menu choice
get_menu_choice() {
    local choice
    while true; do
        read -p "Choice [1-8]: " choice
        case "$choice" in
            [1-8])
                echo "$choice"
                return 0
                ;;
            *)
                print_error "Invalid choice. Please select 1-8."
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
    
    print_info "Hyprland installation functionality will be implemented in Phase 3"
    print_info "This will replace the GNOME/KDE options with Hyprland-only setup"
    
    # TODO: Implement in Phase 3
    # - Remove GNOME/KDE from post_install_script.sh
    # - Add Hyprland package installation
    # - Add Wayland ecosystem tools
}

op_deploy_dotfiles() {
    print_step "Deploy Dotfiles"
    
    if ! validate_state_for_operation "deploy_dotfiles" "$(detect_system_state)"; then
        return 1
    fi
    
    print_info "Dotfiles deployment functionality will be implemented in Phase 4"
    print_info "This will handle i3 → Hyprland config migration and deployment"
    
    # TODO: Implement in Phase 4
    # - Create dotfiles repository structure
    # - Implement config deployment
    # - Add backup/restore functionality
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
                op_system_info
                ;;
            8)
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
