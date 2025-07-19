#!/bin/bash

# Partition operations extracted from install.sh

# Partition schemes
declare -A schemes=(
    [1]="compact: 60-100GB, 8GB swap, rest root (no /home, no timeshift)"
    [2]="standard: 512GB, 16GB swap, 150GB root, 200GB home, 180GB timeshift"
    [3]="massive: 1TB+, 16GB swap, 200GB root, rest split home/timeshift"
)

print_schemes() {
    echo "Available partition schemes:"
    for key in "${!schemes[@]}"; do
        echo "  $key) ${schemes[$key]}"
    done
}

get_partition_input() {
    # Show available disks with details
    echo "Available disks:"
    lsblk -d -o NAME,SIZE,MODEL,VENDOR,SERIAL | grep -E "sd|nvme|vd"
    
    read -p "Target disk (e.g., sda, nvme0n1): " DISK
    DISK="/dev/$DISK"
    
    if [[ ! -b "$DISK" ]]; then
        echo "Error: $DISK not found"
        return 1
    fi
    
    print_schemes
    read -p "Partition scheme [1/2/3]: " SCHEME
    
    if [[ ! "${schemes[$SCHEME]}" ]]; then
        echo "Invalid scheme"
        return 1
    fi
    
    read -p "Admin username: " USERNAME
    
    # Use utility function for password confirmation
    CRYPT_PASS=$(get_confirmed_password "Encryption password")
    USER_PASS=$(get_confirmed_password "User password")
    
    return 0
}

wipe_disk() {
    echo "Wiping disk $DISK..."
    dd if=/dev/zero of="$DISK" bs=1M count=100 2>/dev/null || true
    wipefs -af "$DISK" 2>/dev/null || true
}

create_partitions() {
    echo "Creating partitions for scheme $SCHEME setup..."
    
    # Get disk size in GB
    DISK_SIZE=$(lsblk -b -d -o SIZE "$DISK" | tail -1)
    DISK_GB=$((DISK_SIZE / 1024 / 1024 / 1024))
    
    case "$SCHEME" in
        "1")
            # Compact: EFI: 1GB, Boot: 5GB, LVM: rest (no separate /home)
            parted -s "$DISK" mklabel gpt
            parted -s "$DISK" mkpart primary fat32 1MiB 1025MiB    # EFI
            parted -s "$DISK" set 1 esp on
            parted -s "$DISK" mkpart primary ext4 1025MiB 6145MiB  # Boot
            parted -s "$DISK" mkpart primary 6145MiB 100%         # LVM
            
            SWAP_SIZE="8G"
            ROOT_SIZE="100%FREE"
            CREATE_HOME=false
            TIMESHIFT_PART=""
            ;;
        "2")
            # Standard: EFI: 1GB, Boot: 5GB, LVM: ~330GB, Timeshift: rest
            parted -s "$DISK" mklabel gpt
            parted -s "$DISK" mkpart primary fat32 1MiB 1025MiB
            parted -s "$DISK" set 1 esp on
            parted -s "$DISK" mkpart primary ext4 1025MiB 6145MiB
            parted -s "$DISK" mkpart primary 6145MiB 346145MiB    # ~340GB LVM
            parted -s "$DISK" mkpart primary ext4 346145MiB 100%  # Timeshift
            
            SWAP_SIZE="16G"
            ROOT_SIZE="150G"
            CREATE_HOME=true
            TIMESHIFT_PART="${DISK}4"
            ;;
        "3")
            # Massive: EFI: 1GB, Boot: 5GB, LVM: 70%, Timeshift: 30%
            LVM_END=$((DISK_GB * 70 / 100 + 6))
            parted -s "$DISK" mklabel gpt
            parted -s "$DISK" mkpart primary fat32 1MiB 1025MiB
            parted -s "$DISK" set 1 esp on
            parted -s "$DISK" mkpart primary ext4 1025MiB 6145MiB
            parted -s "$DISK" mkpart primary 6145MiB ${LVM_END}GiB
            parted -s "$DISK" mkpart primary ext4 ${LVM_END}GiB 100%
            
            SWAP_SIZE="16G"
            ROOT_SIZE="200G"
            CREATE_HOME=true
            TIMESHIFT_PART="${DISK}4"
            ;;
    esac
    
    # Set partition variables
    EFI_PART="${DISK}1"
    BOOT_PART="${DISK}2" 
    LVM_PART="${DISK}3"
    
    # Handle nvme naming
    if [[ "$DISK" =~ nvme ]]; then
        EFI_PART="${DISK}p1"
        BOOT_PART="${DISK}p2"
        LVM_PART="${DISK}p3"
        [[ "$TIMESHIFT_PART" ]] && TIMESHIFT_PART="${DISK}p4"
    fi

    echo "Partitions created:"
    echo "  EFI: $EFI_PART"
    echo "  Boot: $BOOT_PART"
    echo "  LVM: $LVM_PART"
    [[ "$TIMESHIFT_PART" ]] && echo "  Timeshift: $TIMESHIFT_PART"
    echo "  Swap: $SWAP_SIZE"
    echo "  Root: $ROOT_SIZE"
    [[ "$CREATE_HOME" == true ]] && echo "  Home: 100%FREE"
    
    sleep 2  # Let kernel recognize partitions
}

setup_encryption() {
    echo "Setting up LUKS encryption..."
    echo -n "$CRYPT_PASS" | cryptsetup luksFormat "$LVM_PART" -
    echo -n "$CRYPT_PASS" | cryptsetup open "$LVM_PART" cryptlvm -
}

setup_lvm() {
    echo "Creating LVM volumes..."
    pvcreate /dev/mapper/cryptlvm
    vgcreate SysVG /dev/mapper/cryptlvm
    
    lvcreate -L "$SWAP_SIZE" SysVG -n swap
    
    if [[ "$CREATE_HOME" == true ]]; then
        lvcreate -L "$ROOT_SIZE" SysVG -n root
        lvcreate -l 100%FREE SysVG -n home
        # Leave some space for fsck
        lvresize -L -512M /dev/SysVG/home
    else
        # Compact scheme: only root partition
        lvcreate -l 100%FREE SysVG -n root
        # Leave some space for fsck
        lvresize -L -512M /dev/SysVG/root
    fi
}

format_partitions() {
    echo "Formatting partitions..."
    mkfs.fat -F32 "$EFI_PART"
    mkfs.ext4 -F "$BOOT_PART"
    mkfs.ext4 -F /dev/SysVG/root
    mkswap /dev/SysVG/swap
    
    [[ "$CREATE_HOME" == true ]] && mkfs.ext4 -F /dev/SysVG/home
    [[ "$TIMESHIFT_PART" ]] && mkfs.ext4 -F "$TIMESHIFT_PART"
}

mount_system() {
    echo "Mounting filesystems..."
    mount /dev/SysVG/root /mnt
    mkdir -p /mnt/boot
    mount "$BOOT_PART" /mnt/boot
    mkdir -p /mnt/boot/efi
    mount "$EFI_PART" /mnt/boot/efi
    
    if [[ "$CREATE_HOME" == true ]]; then
        mkdir -p /mnt/home
        mount /dev/SysVG/home /mnt/home
    fi
    
    swapon /dev/SysVG/swap
    
    if [[ "$TIMESHIFT_PART" ]]; then
        mkdir -p /mnt/run/timeshift/backup
        mount "$TIMESHIFT_PART" /mnt/run/timeshift/backup
    fi
}

unmount_system() {
    echo "Unmounting filesystems..."
    umount -R /mnt 2>/dev/null || true
    swapoff -a 2>/dev/null || true
}

remount_existing_system() {
    local luks_part="$1"
    local crypt_pass="$2"
    
    echo "Opening LUKS partition..."
    if ! echo -n "$crypt_pass" | cryptsetup open "$luks_part" cryptlvm -; then
        return 1
    fi
    
    echo "Mounting filesystems..."
    mount /dev/SysVG/root /mnt
    mkdir -p /mnt/boot /mnt/boot/efi
    
    # Find and mount boot and EFI partitions
    local disk_base
    if [[ "$luks_part" =~ nvme.*p[0-9]+$ ]]; then
        disk_base="${luks_part%p*}"
        mount "${disk_base}p2" /mnt/boot 2>/dev/null || true
        mount "${disk_base}p1" /mnt/boot/efi 2>/dev/null || true
    else
        disk_base="${luks_part%[0-9]*}"
        mount "${disk_base}2" /mnt/boot 2>/dev/null || true
        mount "${disk_base}1" /mnt/boot/efi 2>/dev/null || true
    fi
    
    # Mount home if it exists
    if [[ -e /dev/SysVG/home ]]; then
        mkdir -p /mnt/home
        mount /dev/SysVG/home /mnt/home
    fi
    
    # Activate swap
    swapon /dev/SysVG/swap 2>/dev/null || true
    
    return 0
}
