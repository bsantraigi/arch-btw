#!/bin/bash

# Quick validation script for Phase 2A implementation
# Run this to verify all components are properly structured

echo "=== Phase 2A Implementation Validation ==="
echo

# Check file structure
echo "📁 File Structure:"
files=("setup.sh" "lib/state.sh" "lib/utils.sh" "install.sh" "post_install_script.sh" "reset.sh")
for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (missing)"
    fi
done
echo

# Check setup.sh structure
echo "🔧 setup.sh Analysis:"
if [[ -f "setup.sh" ]]; then
    functions=("show_main_menu" "get_menu_choice" "op_setup_partitions" "op_unmount_system" "op_remount_system" "op_install_base" "op_install_hyprland" "op_deploy_dotfiles" "op_system_info" "main")
    
    for func in "${functions[@]}"; do
        if grep -q "^$func()" setup.sh; then
            echo "  ✅ Function: $func"
        else
            echo "  ❌ Function: $func (missing)"
        fi
    done
fi
echo

# Check lib/state.sh structure  
echo "📊 lib/state.sh Analysis:"
if [[ -f "lib/state.sh" ]]; then
    functions=("detect_system_state" "get_current_disk" "get_state_description" "validate_state_for_operation")
    
    for func in "${functions[@]}"; do
        if grep -q "^$func()" lib/state.sh; then
            echo "  ✅ Function: $func"
        else
            echo "  ❌ Function: $func (missing)"
        fi
    done
fi
echo

# Check lib/utils.sh structure
echo "🛠️  lib/utils.sh Analysis:"
if [[ -f "lib/utils.sh" ]]; then
    functions=("print_header" "print_success" "print_error" "get_confirmed_password" "confirm_operation" "check_root" "cleanup_on_exit")
    
    for func in "${functions[@]}"; do
        if grep -q "^$func()" lib/utils.sh; then
            echo "  ✅ Function: $func"
        else
            echo "  ❌ Function: $func (missing)"
        fi
    done
fi
echo

# Check for proper sourcing
echo "🔗 Library Import Analysis:"
if grep -q 'source.*lib/utils.sh' setup.sh && grep -q 'source.*lib/state.sh' setup.sh; then
    echo "  ✅ Libraries properly sourced in setup.sh"
else
    echo "  ❌ Library sourcing issues in setup.sh"
fi
echo

# Check for key features
echo "⚙️  Feature Implementation:"
features=(
    "Password confirmation:get_confirmed_password"
    "State detection:detect_system_state"
    "Menu display:show_main_menu"
    "Error handling:print_error"
    "Cleanup trap:cleanup_on_exit"
    "Operation validation:validate_state_for_operation"
)

for feature in "${features[@]}"; do
    name="${feature%:*}"
    func="${feature#*:}"
    if grep -rq "$func" lib/ setup.sh 2>/dev/null; then
        echo "  ✅ $name"
    else
        echo "  ❌ $name (not found)"
    fi
done
echo

echo "=== Validation Complete ==="
echo "💡 Run 'sudo bash setup.sh' in Arch Linux to test the menu system"
