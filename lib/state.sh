#!/bin/bash

# System state detection functions

detect_system_state() {
    if cryptsetup status cryptlvm &>/dev/null; then
        if mountpoint -q /mnt; then
            if [[ -f /mnt/etc/hostname ]]; then
                echo "INSTALLED"
            else
                echo "MOUNTED"
            fi
        else
            echo "UNMOUNTED"
        fi
    else
        echo "CLEAN"
    fi
}

get_current_disk() {
    # Try to detect the disk with LUKS partition
    local luks_device
    if luks_device=$(cryptsetup status cryptlvm 2>/dev/null | grep device: | awk '{print $2}'); then
        # Extract the base device (remove partition number)
        if [[ "$luks_device" =~ nvme.*p[0-9]+$ ]]; then
            echo "${luks_device%p*}"
        elif [[ "$luks_device" =~ [a-z]+[0-9]+$ ]]; then
            echo "${luks_device%[0-9]*}"
        else
            echo "$luks_device"
        fi
    else
        # Try to detect available disks
        local available_disks
        available_disks=$(lsblk -d -n -o NAME | grep -E "^(sd|nvme|vd)" | head -1)
        if [[ -n "$available_disks" ]]; then
            echo "/dev/$available_disks"
        else
            echo "No disk detected"
        fi
    fi
}

get_state_description() {
    local state="$1"
    case "$state" in
        "CLEAN")
            echo "No setup detected - ready for fresh installation"
            ;;
        "MOUNTED")
            echo "LUKS opened and filesystems mounted at /mnt"
            ;;
        "UNMOUNTED")
            echo "LUKS partition exists but not mounted"
            ;;
        "INSTALLED")
            echo "Base system installed and ready for configuration"
            ;;
        *)
            echo "Unknown state"
            ;;
    esac
}

validate_state_for_operation() {
    local operation="$1"
    local current_state="$2"
    
    case "$operation" in
        "setup_partitions")
            # Can always run - will wipe existing setup
            return 0
            ;;
        "unmount_system")
            if [[ "$current_state" == "MOUNTED" || "$current_state" == "INSTALLED" ]]; then
                return 0
            else
                echo "Error: Nothing to unmount. Current state: $current_state"
                return 1
            fi
            ;;
        "remount_system")
            if [[ "$current_state" == "UNMOUNTED" ]]; then
                return 0
            else
                echo "Error: Cannot remount. Current state: $current_state"
                echo "       Expected state: UNMOUNTED"
                return 1
            fi
            ;;
        "install_base")
            if [[ "$current_state" == "MOUNTED" ]]; then
                return 0
            else
                echo "Error: Base installation requires mounted filesystems."
                echo "       Current state: $current_state"
                echo "       Expected state: MOUNTED"
                return 1
            fi
            ;;
        "install_hyprland"|"deploy_dotfiles"|"setup_virtualbox"|"setup_timeshift"|"configure_workspace")
            if [[ "$current_state" == "INSTALLED" ]]; then
                return 0
            else
                echo "Error: $operation requires installed base system."
                echo "       Current state: $current_state"
                echo "       Expected state: INSTALLED"
                return 1
            fi
            ;;
    esac
    
    return 0
}
