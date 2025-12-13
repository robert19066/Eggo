#!/bin/bash

# Return JSON output for web interface
check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_ID=$ID
        OS_VERSION=$VERSION_ID
    else
        echo '{"supported": false, "error": "Cannot detect OS"}'
        exit 1
    fi
    
    ARCH=$(uname -m)
    
    # Check if Debian-based
    if [[ "$OS_ID" =~ ^(debian|ubuntu|linuxmint|pop|elementary|lubuntu|kali|zorin)$ ]]; then
        # Check if apt is available
        if command -v apt-get &> /dev/null; then
            echo "{\"supported\": true, \"os_name\": \"$OS_NAME\", \"os_id\": \"$OS_ID\", \"version\": \"$OS_VERSION\", \"arch\": \"$ARCH\", \"package_manager\": \"apt\"}"
        else
            echo "{\"supported\": false, \"error\": \"apt-get not found\", \"os_name\": \"$OS_NAME\"}"
        fi
    else
        echo "{\"supported\": false, \"error\": \"Not a Debian-based distribution\", \"os_name\": \"$OS_NAME\", \"os_id\": \"$OS_ID\", \"suggestion\": \"Use fresh-eggs for RPM-based distros or get-eggs for Arch\"}"
    fi
}

# Check if running with root privileges
check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Main execution
case "$1" in
    "check")
        check_os
        ;;
    "root")
        check_root
        ;;
    *)
        check_os
        ;;
esac