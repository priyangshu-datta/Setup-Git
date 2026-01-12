#!/bin/bash

# GitHub Setup Bootstrap Launcher
# Downloads, runs, and cleans up the real setup script

set -e

REPO_USER="priyangshu-datta"
REPO_NAME="setup-git"
SCRIPT_NAME="setup-git.sh"
RAW_URL="https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/main/${SCRIPT_NAME}"
TEMP_SCRIPT="/tmp/${SCRIPT_NAME}.$$"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Cleanup on exit
cleanup() {
    if [[ -f "$TEMP_SCRIPT" ]]; then
        rm -f "$TEMP_SCRIPT"
        log "Temporary script cleaned up"
    fi
}
trap cleanup EXIT

# Main flow
log "Downloading GitHub setup script..."
if ! curl -fsSL -o "$TEMP_SCRIPT" "$RAW_URL"; then
    error "Failed to download script from $RAW_URL"
    exit 1
fi

log "Making script executable..."
chmod +x "$TEMP_SCRIPT"

success "Running GitHub setup..."
"$TEMP_SCRIPT"

success "GitHub setup completed!"
