#!/bin/bash

# This script installs penguins-eggs and returns JSON status updates

log_status() {
    echo "{\"status\": \"$1\", \"message\": \"$2\"}"
}

log_error() {
    echo "{\"status\": \"error\", \"message\": \"$1\"}"
    exit 1
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root. Please use sudo."
fi

# Check if repository is already configured
if [ -f /etc/apt/trusted.gpg.d/penguins-eggs.gpg ] && [ -f /etc/apt/sources.list.d/penguins-eggs.list ]; then
    log_status "info" "Repository already configured"
else
    log_status "progress" "Adding penguins-eggs repository..."
    
    # Add GPG key
    curl -fsSL https://pieroproietti.github.io/penguins-eggs-ppa/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/penguins-eggs.gpg 2>/dev/null
    
    if [ $? -ne 0 ]; then
        log_error "Failed to add GPG key"
    fi
    
    # Add repository
    echo "deb [arch=$(dpkg --print-architecture)] https://pieroproietti.github.io/penguins-eggs-ppa ./" | tee /etc/apt/sources.list.d/penguins-eggs.list > /dev/null
    
    log_status "success" "Repository added successfully"
fi

# Update package lists
log_status "progress" "Updating package lists..."
apt-get update -qq 2>&1
if [ $? -ne 0 ]; then
    log_error "Failed to update package lists"
fi

# Install penguins-eggs
log_status "progress" "Installing penguins-eggs..."
apt-get install -y penguins-eggs 2>&1

if [ $? -ne 0 ]; then
    log_error "Installation failed"
fi

# Verify installation
if command -v eggs &> /dev/null; then
    INSTALLED_VERSION=$(eggs version 2>/dev/null | head -1 || echo "unknown")
    log_status "complete" "Installation complete! Version: $INSTALLED_VERSION"
else
    log_error "Installation verification failed"
fi