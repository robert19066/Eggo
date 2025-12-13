#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${CYAN}-- Eggo Installer Selector --${RESET}"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${YELLOW}[WARN]${RESET} Running as root. Web UI will run as root user."
    echo ""
fi

# Make scripts executable
chmod +x ./eggo_shell.sh
chmod +x ./WebUI/oscheck.sh
chmod +x ./WebUI/debinstall.sh 2>/dev/null
chmod +x ./WebUI/server.js 2>/dev/null

echo "--Please choose an installation method:--"
echo "1) CLI (command-line)"
echo "2) Web-based UI"
echo ""
read -p "Enter your choice (1 or 2): " choice

case $choice in
    1)
        echo ""
        echo -e "${GREEN}Starting CLI installer...${RESET}"
        echo ""
        ./eggo_shell.sh
        ;;
    2)
        echo ""
        echo -e "${GREEN}Preparing Web UI...${RESET}"
        echo ""
        
        # Check for Node.js
        if ! command -v node &> /dev/null; then
            echo -e "${YELLOW}Node.js not found. Installing...${RESET}"
            
            # Detect package manager
            if command -v apt-get &> /dev/null; then
                sudo apt-get update -qq
                sudo apt-get install -y nodejs npm
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y nodejs npm
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm nodejs npm
            else
                echo -e "${RED}[ERROR]${RESET} Cannot install Node.js automatically."
                echo "Please install Node.js manually from: https://nodejs.org"
                exit 1
            fi
            
            if ! command -v node &> /dev/null; then
                echo -e "${RED}[ERROR]${RESET} Node.js installation failed"
                exit 1
            fi
            echo -e "${GREEN}[OK]${RESET} Node.js installed"
        else
            echo -e "${GREEN}[OK]${RESET} Node.js found ($(node -v))"
        fi
        
        # Check for npm
        if ! command -v npm &> /dev/null; then
            echo -e "${RED}[ERROR]${RESET} npm not found"
            exit 1
        fi
        
        # Navigate to WebUI directory
        cd WebUI || exit 1
        
        # Check if node_modules exists
        if [ ! -d "node_modules" ]; then
            echo -e "${CYAN}Installing dependencies...${RESET}"
            npm install express cors 2>/dev/null
        fi
        
        # Check for Vite
        if ! npm list vite &> /dev/null; then
            echo -e "${CYAN}Installing Vite...${RESET}"
            npm install -D vite
        fi
        
        
        # Start the backend server in background
        node server.js &
        SERVER_PID=$!
        
        # Wait a moment for server to start
        sleep 2
        
        # Start Vite dev server
        npx vite --host
        
        # Cleanup: kill the backend server when vite stops
        kill $SERVER_PID 2>/dev/null
        ;;
    *)
        echo ""
        echo -e "${RED}[ERROR]${RESET} Invalid choice"
        exit 1
        ;;
esac