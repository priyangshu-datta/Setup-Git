#!/bin/bash
 
# GitHub Setup Script
# Supports Linux, macOS, and Windows (via WSL/Git Bash)
# Usage: curl -fsSL https://raw.githubusercontent.com/priyangshu-datta/setup-git/main/main.sh | bash
 
set -e
 
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
 
# Log functions
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}
warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}
error() {
    echo -e "${RED}[ERROR]${NC} $1"
}
success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}
 
# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     OS=Linux;;
        Darwin*)    OS=macOS;;
        CYGWIN*|MINGW32*|MSYS*|MINGW64*)
                    OS=Windows;;
        *)          OS="UNKNOWN"
    esac
    log "Detected OS: $OS"
}
 
# Install required packages
install_packages() {
    case $OS in
        Linux)
            if command -v apt-get &> /dev/null; then
                log "Installing required packages (Debian/Ubuntu)..."
                sudo apt-get update
                sudo apt-get install -y git curl
            elif command -v yum &> /dev/null; then
                log "Installing required packages (RHEL/CentOS)..."
                sudo yum install -y git curl
            elif command -v dnf &> /dev/null; then
                log "Installing required packages (Fedora)..."
                sudo dnf install -y git curl
            elif command -v pacman &> /dev/null; then
                log "Installing required packages (Arch)..."
                sudo pacman -Syu --noconfirm git curl
            else
                warn "Unsupported Linux package manager. Please install git and curl manually."
            fi
            ;;
        macOS)
            if ! command -v git &> /dev/null; then
                log "Installing Xcode Command Line Tools..."
                xcode-select --install
                log "Press Enter when installation completes"
                read -r
            fi
            ;;
        Windows)
            if ! command -v git &> /dev/null; then
                error "Git not found. Please install Git for Windows:"
                echo "https://git-scm.com/download/win"
                exit 1
            fi
            ;;
    esac
}
 
# Configure Git identity
configure_git() {
    log "Configuring Git identity..."
    
    if ! git config --global user.name | grep -q '.'; then
        read -rp "Enter your full name: " name
        git config --global user.name "$name"
    fi
    
    if ! git config --global user.email | grep -q '.'; then
        read -rp "Enter your GitHub email: " email
        git config --global user.email "$email"
    fi
    
    # Set default branch name
    git config --global init.defaultBranch main
    
    success "Git identity configured"
}
 
# Setup SSH keys
setup_ssh() {
    log "Setting up SSH keys..."
    SSH_DIR="$HOME/.ssh"
    KEY_PATH="$SSH_DIR/id_ed25519"
    
    # Create .ssh directory if missing
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    
    # Generate new key if needed
    if [ ! -f "$KEY_PATH" ]; then
        log "Generating new SSH key..."
        read -rp "Enter email for SSH key (press Enter to use Git email): " ssh_email
        ssh_email=${ssh_email:-$(git config --global user.email)}
        
        ssh-keygen -t ed25519 -C "$ssh_email" -f "$KEY_PATH" -N "" -q
        success "SSH key generated"
    else
        log "SSH key already exists"
    fi
    
    # Start SSH agent
    case $OS in
        Linux|macOS)
            eval "$(ssh-agent -s 2>/dev/null)"
            ssh-add "$KEY_PATH" 2>/dev/null
            ;;
        Windows)
            # Git Bash uses Windows SSH agent
            if ! ssh-add -l &>/dev/null; then
                eval "$(ssh-agent -s)"
                ssh-add "$KEY_PATH"
            fi
            ;;
    esac
    
    # Display public key
    log "Your public key:"
    echo "--------------------------------------------------"
    cat "$KEY_PATH.pub"
    echo "--------------------------------------------------"
    
    success "SSH key setup complete"
    echo
    warn "ACTION REQUIRED:"
    echo "1. Copy the public key above"
    echo "2. Add it to your GitHub account:"
    echo "   https://github.com/settings/ssh/new"
    echo "3. Title: $(hostname)-$(date +%Y%m%d)"
    echo
    read -rp "Press Enter after adding the key to GitHub..."
}
 
# Test GitHub connection
test_connection() {
    log "Testing GitHub connection..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        success "SSH connection to GitHub verified!"
    else
        error "SSH connection failed. Please verify:"
        echo "1. Key added to GitHub"
        echo "2. SSH agent running"
        echo "3. Key added to agent (ssh-add -l)"
        exit 1
    fi
}
 
# Clone user's dotfiles repository
clone_repo() {
    log "Cloning configuration repository..."
    read -rp "Enter your GitHub username: " username
    read -rp "Enter repository name (default: dotfiles): " repo
    repo=${repo:-dotfiles}
    
    if [ -d "$repo" ]; then
        warn "Directory $repo already exists. Skipping clone."
    else
        git clone git@github.com:"$username"/"$repo".git
        success "Repository cloned successfully"
    fi
}
 
# Main execution
main() {
    echo "=================================="
    echo "   GitHub Setup Script"
    echo "=================================="
    
    detect_os
    install_packages
    configure_git
    setup_ssh
    test_connection
    # clone_repo
    
    echo
    success "GitHub setup completed!"
    echo "Next steps:"
    echo "- Configure your dotfiles repository"
    echo "- Run any additional setup scripts from your repo"
}
 
main "$@"
