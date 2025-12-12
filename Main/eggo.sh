#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RESET='\033[0m'
rainbow() {
local text="$1"
local colors=("$RED" "$YELLOW" "$GREEN" "$CYAN" "$BLUE" "$MAGENTA")
local color_count=${#colors[@]}
local output=""
for (( i=0; i<${#text}; i++ )); do
local color_index=$((i % color_count))
output+="${colors[$color_index]}${text:$i:1}"
done
echo -e "${output}${RESET}"
}
status() {
echo -e "${CYAN}==>${RESET} $1"
}
success() {
echo -e "${GREEN}[OK]${RESET} $1"
}
error() {
echo -e "${RED}[ERROR]${RESET} $1"
}
warn() {
echo -e "${YELLOW}[WARN]${RESET} $1"
}
clear
rainbow "<- Eggo - The simpler installer for penguins-eggs! ->"
echo -e "${CYAN}By robert19066${RESET}"
echo -e "${CYAN}In colaboration with Piero Proietti(creator of penguins-eggs)!${RESET}"
echo ""
if [[ $EUID -ne 0 ]]; then
error "This script must be run as root (use sudo)"
exit 1
fi
status "Detecting system..."
if [ -f /etc/os-release ]; then
. /etc/os-release
OS_NAME=$NAME
OS_ID=$ID
else
error "Cannot detect OS"
exit 1
fi
ARCH=$(uname -m)
echo "  Linux Distro: $OS_NAME"
echo "  CPU Arhitecture: $ARCH"
echo ""

if [[ ! "$OS_ID" =~ ^(debian|ubuntu|linuxmint|pop|elementary|lubuntu)$ ]]; then
error "This installer only supports Debian-based distributions"
echo ""
echo "For other distros, use:"
echo "  - Arch/Manjaro: Use get-eggs script or AUR"
echo "  - Fedora/OpenSUSE/RHEL: Use fresh-eggs script"
echo "  - Universal: Download AppImage from GitHub releases"
exit 1
else
success "Apt-supported distribution detected"
rainbow "System supported!"
echo ""
fi

# Check if repository is already configured
if [ -f /etc/apt/trusted.gpg.d/penguins-eggs.gpg ] && [ -f /etc/apt/sources.list.d/penguins-eggs.list ]; then
    success "Repository already configured, skipping..."
    echo ""
else
    status "Adding penguins-eggs repository..."
    curl -fsSL https://pieroproietti.github.io/penguins-eggs-ppa/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/penguins-eggs.gpg 2>/dev/null
    if [ $? -ne 0 ]; then
        error "Failed to add GPG key"
        exit 1
    fi
    echo "deb [arch=$(dpkg --print-architecture)] https://pieroproietti.github.io/penguins-eggs-ppa ./" | tee /etc/apt/sources.list.d/penguins-eggs.list > /dev/null
    success "Repository added"
    echo ""
fi

status "Updating package lists..."
apt-get update -qq 2>&1 | grep -i "penguins-eggs" || true
echo ""
status "Installing penguins-eggs..."
apt-get install -y penguins-eggs 2>&1 | grep -E "(Unpacking|Setting up|penguins-eggs)" || apt-get install -y penguins-eggs
if command -v eggs &> /dev/null; then
echo ""
success "Installation complete!"
INSTALLED_VERSION=$(eggs version 2>/dev/null | head -1 || echo "unknown")
echo "  Version: $INSTALLED_VERSION"
else
echo ""
error "Installation failed"
exit 1
fi
echo ""
rainbow "--Penguin's Eggs installed!--"
echo ""
echo "Run 'eggs' to get started"
echo "Documentation: https://penguins-eggs.net"
echo ""