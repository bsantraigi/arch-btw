#!/bin/bash

# Common utility functions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

print_step() {
    echo -e "${PURPLE}→ $1${NC}"
}

# Password confirmation with retry
get_confirmed_password() {
    local prompt="$1"
    local pass1 pass2
    
    while true; do
        read -s -p "$prompt: " pass1
        echo
        read -s -p "Confirm $prompt: " pass2
        echo
        
        if [[ -z "$pass1" ]]; then
            print_error "Password cannot be empty. Try again."
            continue
        fi
        
        if [[ "$pass1" == "$pass2" ]]; then
            echo "$pass1"
            break
        else
            print_error "Passwords don't match. Try again."
        fi
    done
}

# Confirm operation with user
confirm_operation() {
    local message="$1"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        read -p "$message [Y/n]: " response
        response=${response:-y}
    else
        read -p "$message [y/N]: " response
        response=${response:-n}
    fi
    
    case "$response" in
        [Yy]|[Yy][Ee][Ss])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Wait for user to press enter
press_enter_to_continue() {
    echo
    read -p "Press Enter to continue..."
    echo
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        print_info "Please run: sudo $0"
        exit 1
    fi
}

# Check if we're in the Arch Linux live environment
check_arch_live() {
    if [[ ! -f /etc/arch-release ]]; then
        print_warning "This doesn't appear to be an Arch Linux system"
        if ! confirm_operation "Continue anyway?"; then
            exit 1
        fi
    fi
}

# Validate disk exists
validate_disk() {
    local disk="$1"
    
    if [[ ! -b "$disk" ]]; then
        print_error "Disk $disk not found or not a block device"
        return 1
    fi
    
    return 0
}

# Show available disks
show_available_disks() {
    print_info "Available disks:"
    lsblk -d -o NAME,SIZE,MODEL,VENDOR | grep -E "NAME|sd|nvme|vd" | head -10
}

# Cleanup function for script exit
cleanup_on_exit() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        print_error "Script exited with error code $exit_code"
        print_info "Check the output above for error details"
    fi
    
    # Only unmount if we mounted something during this script run
    if [[ "$SCRIPT_MOUNTED" == "true" ]]; then
        print_info "Cleaning up mounted filesystems..."
        umount -R /mnt 2>/dev/null || true
        cryptsetup close cryptlvm 2>/dev/null || true
    fi
}

# Set up trap for cleanup
setup_cleanup_trap() {
    trap cleanup_on_exit EXIT
}

# Log function for debugging
log_operation() {
    local operation="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $operation" >> /tmp/setup.log
}
