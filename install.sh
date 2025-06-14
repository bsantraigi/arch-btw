#!/bin/bash
set -e

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

get_user_input() {
    echo "=== Arch Linux Auto-Install ==="
    
    # Show available disks with details
    echo "Available disks:"
    lsblk -d -o NAME,SIZE,MODEL,VENDOR,SERIAL | grep -E "sd|nvme|vd"
    
    read -p "Target disk (e.g., sda, nvme0n1): " DISK
    DISK="/dev/$DISK"
    
    if [[ ! -b "$DISK" ]]; then
        echo "Error: $DISK not found"
        exit 1
    fi
    
    print_schemes
    read -p "Partition scheme [1/2/3]: " SCHEME
    
    if [[ ! "${schemes[$SCHEME]}" ]]; then
        echo "Invalid scheme"
        exit 1
    fi
    
    read -p "Admin username: " USERNAME
    read -s -p "Encryption password: " CRYPT_PASS
    echo
    read -s -p "User password: " USER_PASS
    echo
}

wipe_disk() {
    echo "Wiping disk $DISK..."
    dd if=/dev/zero of="$DISK" bs=1M count=100 2>/dev/null || true
    wipefs -af "$DISK" 2>/dev/null || true
}

create_partitions() {
    echo "Creating partitions for $SCHEME setup..."
    
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
            ROOT_SIZE="100%FREE"  # Use all remaining space
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

    # Echo summary
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
    mkdir -p /mnt/boot{,/efi}
    mount "$BOOT_PART" /mnt/boot
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

install_base() {
    echo "Installing base system..."
    pacstrap /mnt base base-devel linux linux-firmware lvm2 cryptsetup grub efibootmgr networkmanager sudo vim git timeshift
    genfstab -U /mnt >> /mnt/etc/fstab
}

configure_system() {
    echo "Configuring system..."
    
    # Generate crypttab
    LUKS_UUID=$(blkid -s UUID -o value "$LVM_PART")
    echo "cryptlvm UUID=$LUKS_UUID none luks" > /mnt/etc/crypttab
    
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

echo "Configuration complete!"
EOF

    chmod +x /mnt/root/configure.sh
    arch-chroot /mnt /root/configure.sh "$USERNAME" "$USER_PASS" "$LUKS_UUID"
    rm /mnt/root/configure.sh
}

cleanup() {
    echo "Cleaning up..."
    umount -R /mnt 2>/dev/null || true
    cryptsetup close cryptlvm 2>/dev/null || true
}

main() {
    get_user_input
    wipe_disk
    create_partitions
    setup_encryption
    setup_lvm
    format_partitions
    mount_system
    install_base
    configure_system
    cleanup
    
    echo "Installation complete! Remove installation media and reboot."
    echo "Login as: $USERNAME"
}

# Trap cleanup on exit
trap cleanup EXIT
main