#!/bin/bash

# Reset script - unmount and close everything for clean restart

echo "Unmounting filesystems..."
umount -R /mnt 2>/dev/null || true
swapoff -a 2>/dev/null || true

echo "Deactivating LVM..."
vgchange -an SysVG 2>/dev/null || true
vgremove -f SysVG 2>/dev/null || true
pvremove /dev/mapper/cryptlvm 2>/dev/null || true

echo "Closing LUKS partition..."
cryptsetup close cryptlvm 2>/dev/null || true

echo "Reset complete. Ready for fresh install."
