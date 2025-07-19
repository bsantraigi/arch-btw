# Menu System Design

## Architecture

**Entry Point**: `setup.sh` - Single command interface
**Approach**: Bash-based modular system with state awareness

## Core Components

### 1. Main Menu Interface
```
=== Arch Linux Personal Setup Tool ===

System Status: [UNMOUNTED / MOUNTED / INSTALLED]
Current Disk: /dev/nvme0n1 (if detected)

Operations:
1) Setup/Recreate LUKS + Partition + LVM
2) Unmount Configuration  
3) Remount Configuration
4) Install Base OS + Software
5) Install Hyprland + Essential Tools
6) Deploy Dotfiles
7) System Status & Info
8) Exit

Choice [1-8]: 
```

### 2. State Management

**System States**:
- `CLEAN`: No setup detected
- `MOUNTED`: LUKS opened, LVM mounted
- `UNMOUNTED`: LUKS exists but closed
- `INSTALLED`: Base system installed

**State Detection Logic**:
```bash
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
```

### 3. Password Confirmation System

```bash
get_confirmed_password() {
    local prompt="$1"
    local pass1 pass2
    
    while true; do
        read -s -p "$prompt: " pass1
        echo
        read -s -p "Confirm $prompt: " pass2
        echo
        
        if [[ "$pass1" == "$pass2" ]]; then
            echo "$pass1"
            break
        else
            echo "Passwords don't match. Try again."
        fi
    done
}
```

### 4. Error Handling

- Validate prerequisites before each operation
- Rollback on failures
- Clear error messages with suggested actions
- Automatic cleanup on script exit

### 5. Modular Operations

Each menu option maps to a dedicated function:
- `op_setup_partitions()`
- `op_unmount_system()`
- `op_remount_system()`
- `op_install_base()`
- `op_install_hyprland()`
- `op_deploy_dotfiles()`
- `op_system_info()`

## Implementation Priority

1. **Phase 2A**: Basic menu framework + state detection
2. **Phase 2B**: Integration with existing install.sh functions
3. **Phase 2C**: Password confirmation system
4. **Phase 2D**: Error handling and recovery

## File Structure
```
setup.sh           # Main menu interface
lib/
├── state.sh       # State detection functions
├── partitions.sh  # Partition operations (from install.sh)
├── install.sh     # Base installation functions
├── hyprland.sh    # Hyprland setup
├── dotfiles.sh    # Dotfiles deployment
└── utils.sh       # Common utilities
```
