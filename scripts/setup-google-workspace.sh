#!/usr/bin/env bash
# ============================================================================
# Google Workspace MCP Setup Script
# Sets up Google Workspace integration for OpenCode (and optionally Claude Code)
# Supports: Fedora Linux, macOS
# ============================================================================

set -euo pipefail

# --- Colors & formatting ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}ℹ${NC}  $*"; }
success() { echo -e "${GREEN}✓${NC}  $*"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
error()   { echo -e "${RED}✗${NC}  $*"; }
header()  { echo -e "\n${BOLD}${CYAN}═══ $* ═══${NC}\n"; }
step()    { echo -e "${BOLD}→${NC} $*"; }

# --- Detect OS ---
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ -f /etc/fedora-release ]]; then
        OS="fedora"
    elif [[ -f /etc/redhat-release ]]; then
        OS="rhel"
    else
        OS="linux"
    fi
    echo "$OS"
}

# --- Config file paths ---
OPENCODE_CONFIG_DIR="${HOME}/.config/opencode"
OPENCODE_CONFIG="${OPENCODE_CONFIG_DIR}/opencode.jsonc"
CREDENTIALS_DIR="${HOME}/.google_workspace_mcp/credentials"

# ============================================================================
# STEP 1: Welcome & prerequisites
# ============================================================================

header "Google Workspace MCP Setup"

echo -e "This script will set up Google Workspace integration for OpenCode."
echo -e "Once complete, you'll be able to access Gmail, Google Docs, Drive,"
echo -e "Calendar, Sheets, and more directly from your AI coding assistant.\n"

OS=$(detect_os)
info "Detected OS: ${BOLD}${OS}${NC}"

# --- Check Python ---
step "Checking Python 3.10+..."
if command -v python3 &>/dev/null; then
    PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
    PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)
    if [[ "$PYTHON_MAJOR" -ge 3 && "$PYTHON_MINOR" -ge 10 ]]; then
        success "Python ${PYTHON_VERSION} found"
    else
        error "Python ${PYTHON_VERSION} found, but 3.10+ is required"
        if [[ "$OS" == "macos" ]]; then
            echo "  Install with: brew install python@3.12"
        elif [[ "$OS" == "fedora" ]]; then
            echo "  Install with: sudo dnf install python3.12"
        fi
        exit 1
    fi
else
    error "Python 3 not found"
    if [[ "$OS" == "macos" ]]; then
        echo "  Install with: brew install python@3.12"
    elif [[ "$OS" == "fedora" ]]; then
        echo "  Install with: sudo dnf install python3"
    fi
    exit 1
fi

# --- Check/install uv ---
step "Checking uv (Python package manager)..."
if command -v uv &>/dev/null; then
    success "uv found: $(uv --version)"
else
    warn "uv not found. Installing..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # Source the env so uv is available in this session
    export PATH="${HOME}/.local/bin:${PATH}"
    if command -v uv &>/dev/null; then
        success "uv installed: $(uv --version)"
    else
        error "Failed to install uv. Install manually: https://docs.astral.sh/uv/"
        exit 1
    fi
fi

# --- Check uvx ---
step "Checking uvx..."
if command -v uvx &>/dev/null; then
    success "uvx found"
else
    # uvx is bundled with uv since v0.1.24
    if uv tool --help &>/dev/null; then
        success "uvx available via uv tool"
    else
        error "uvx not available. Please update uv: uv self update"
        exit 1
    fi
fi

# --- Check jq ---
step "Checking jq (JSON processor)..."
if command -v jq &>/dev/null; then
    success "jq found"
else
    warn "jq not found. Installing..."
    if [[ "$OS" == "macos" ]]; then
        brew install jq
    elif [[ "$OS" == "fedora" || "$OS" == "rhel" ]]; then
        sudo dnf install -y jq
    else
        sudo apt-get install -y jq 2>/dev/null || {
            error "Could not install jq. Install manually."
            exit 1
        }
    fi
    success "jq installed"
fi

# --- Pre-install workspace-mcp ---
step "Pre-installing workspace-mcp package..."
uvx workspace-mcp --help &>/dev/null 2>&1 && success "workspace-mcp available" || {
    info "Downloading workspace-mcp (this may take a moment)..."
    uv tool install workspace-mcp 2>/dev/null || true
    success "workspace-mcp installed"
}

# ============================================================================
# STEP 2: Google Cloud OAuth credentials
# ============================================================================

header "Google Cloud Setup"

echo -e "You need OAuth credentials from Google Cloud Console."
echo -e "If you already have them, select 'I have credentials'.\n"

echo -e "${BOLD}Do you already have Google OAuth credentials?${NC}"
echo "  1) Yes, I have a Client ID and Client Secret"
echo "  2) No, I need to create them (will open browser)"
echo ""
read -rp "Choice [1/2]: " HAS_CREDS

if [[ "$HAS_CREDS" == "2" ]]; then
    header "Creating Google Cloud OAuth Credentials"

    echo -e "${BOLD}Follow these steps in your browser:${NC}\n"
    echo "  1. Go to Google Cloud Console"
    echo "  2. Create a new project (or select an existing one)"
    echo "  3. Go to: APIs & Services → Credentials"
    echo "  4. Click: Create Credentials → OAuth Client ID"
    echo "  5. Application type: ${BOLD}Desktop Application${NC}"
    echo "  6. Name it: 'OpenCode Workspace MCP'"
    echo "  7. Click Create"
    echo "  8. Copy the Client ID and Client Secret"
    echo ""
    echo -e "  ${BOLD}Then enable these APIs${NC} (APIs & Services → Library):"
    echo "    • Gmail API"
    echo "    • Google Drive API"
    echo "    • Google Calendar API"
    echo "    • Google Docs API"
    echo "    • Google Sheets API"
    echo ""

    # Open the console
    if [[ "$OS" == "macos" ]]; then
        open "https://console.cloud.google.com/apis/credentials" 2>/dev/null || true
    else
        xdg-open "https://console.cloud.google.com/apis/credentials" 2>/dev/null || true
    fi

    echo -e "${YELLOW}Press Enter when you've created the credentials and enabled the APIs...${NC}"
    read -r
fi

# --- Collect credentials ---
echo ""
read -rp "$(echo -e "${BOLD}Google OAuth Client ID:${NC} ")" GOOGLE_CLIENT_ID
if [[ -z "$GOOGLE_CLIENT_ID" ]]; then
    error "Client ID is required"
    exit 1
fi

read -rsp "$(echo -e "${BOLD}Google OAuth Client Secret:${NC} ")" GOOGLE_CLIENT_SECRET
echo ""
if [[ -z "$GOOGLE_CLIENT_SECRET" ]]; then
    error "Client Secret is required"
    exit 1
fi

success "Credentials received"

# ============================================================================
# STEP 3: Access level & tool tier
# ============================================================================

header "Configuration"

echo -e "${BOLD}What level of access do you need?${NC}"
echo "  1) Read-only (recommended) — view emails, docs, calendar, drive"
echo "  2) Full access — also send emails, edit docs, create events"
echo ""
read -rp "Choice [1/2] (default: 1): " ACCESS_LEVEL
ACCESS_LEVEL="${ACCESS_LEVEL:-1}"

if [[ "$ACCESS_LEVEL" == "1" ]]; then
    READ_ONLY="true"
    ACCESS_DESC="read-only"
    success "Read-only access selected"
else
    READ_ONLY="false"
    ACCESS_DESC="full access"
    success "Full access selected"
fi

echo ""
echo -e "${BOLD}Which tools do you want available?${NC}"
echo "  1) Core (recommended) — search, read, create across all services"
echo "  2) Extended — adds labels, folders, batch ops, advanced search"
echo "  3) Complete — everything including comments, admin functions"
echo ""
read -rp "Choice [1/2/3] (default: 1): " TOOL_TIER_CHOICE
TOOL_TIER_CHOICE="${TOOL_TIER_CHOICE:-1}"

case "$TOOL_TIER_CHOICE" in
    1) TOOL_TIER="core" ;;
    2) TOOL_TIER="extended" ;;
    3) TOOL_TIER="complete" ;;
    *) TOOL_TIER="core" ;;
esac
success "Tool tier: ${TOOL_TIER}"

# ============================================================================
# STEP 4: Configure OpenCode
# ============================================================================

header "Configuring OpenCode"

# Build the command args
MCP_ARGS='["uvx", "workspace-mcp", "--tool-tier", "'"${TOOL_TIER}"'"'
if [[ "$READ_ONLY" == "true" ]]; then
    MCP_ARGS="${MCP_ARGS}"', "--read-only"'
fi
MCP_ARGS="${MCP_ARGS}]"

if [[ -f "$OPENCODE_CONFIG" ]]; then
    step "Updating existing OpenCode config..."

    # Check if google-workspace already exists in the config
    if grep -q "google-workspace" "$OPENCODE_CONFIG" 2>/dev/null; then
        warn "google-workspace MCP already exists in config. Replacing..."
        # Use a temp file approach with Python for safe JSONC editing
        python3 -c "
import json, re, sys

with open('$OPENCODE_CONFIG', 'r') as f:
    content = f.read()

# Strip JSONC comments for parsing
stripped = re.sub(r'//.*$', '', content, flags=re.MULTILINE)
stripped = re.sub(r'/\*.*?\*/', '', stripped, flags=re.DOTALL)
config = json.loads(stripped)

config.setdefault('mcp', {})
config['mcp']['google-workspace'] = {
    'type': 'local',
    'command': json.loads('$MCP_ARGS'),
    'environment': {
        'GOOGLE_OAUTH_CLIENT_ID': '$GOOGLE_CLIENT_ID',
        'GOOGLE_OAUTH_CLIENT_SECRET': '$GOOGLE_CLIENT_SECRET'
    },
    'enabled': True
}

with open('$OPENCODE_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')
"
    else
        # Add google-workspace to existing mcp section
        python3 -c "
import json, re, sys

with open('$OPENCODE_CONFIG', 'r') as f:
    content = f.read()

# Strip JSONC comments for parsing
stripped = re.sub(r'//.*$', '', content, flags=re.MULTILINE)
stripped = re.sub(r'/\*.*?\*/', '', stripped, flags=re.DOTALL)
config = json.loads(stripped)

config.setdefault('mcp', {})
config['mcp']['google-workspace'] = {
    'type': 'local',
    'command': json.loads('$MCP_ARGS'),
    'environment': {
        'GOOGLE_OAUTH_CLIENT_ID': '$GOOGLE_CLIENT_ID',
        'GOOGLE_OAUTH_CLIENT_SECRET': '$GOOGLE_CLIENT_SECRET'
    },
    'enabled': True
}

with open('$OPENCODE_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')
"
    fi
    success "OpenCode config updated"
else
    warn "OpenCode config not found at ${OPENCODE_CONFIG}"
    info "Creating minimal config with Google Workspace MCP..."
    mkdir -p "$OPENCODE_CONFIG_DIR"
    cat > "$OPENCODE_CONFIG" <<EOCONFIG
{
  "\$schema": "https://opencode.ai/config.json",
  "mcp": {
    "google-workspace": {
      "type": "local",
      "command": ${MCP_ARGS},
      "environment": {
        "GOOGLE_OAUTH_CLIENT_ID": "${GOOGLE_CLIENT_ID}",
        "GOOGLE_OAUTH_CLIENT_SECRET": "${GOOGLE_CLIENT_SECRET}"
      },
      "enabled": true
    }
  }
}
EOCONFIG
    success "OpenCode config created"
fi

# ============================================================================
# STEP 5: Optionally configure Claude Code
# ============================================================================

echo ""
echo -e "${BOLD}Do you also want to set up Google Workspace for Claude Code?${NC}"
echo "  1) Yes"
echo "  2) No"
echo ""
read -rp "Choice [1/2] (default: 2): " SETUP_CLAUDE
SETUP_CLAUDE="${SETUP_CLAUDE:-2}"

if [[ "$SETUP_CLAUDE" == "1" ]]; then
    step "Configuring Claude Code..."
    if command -v claude &>/dev/null; then
        CLAUDE_ARGS="uvx workspace-mcp --tool-tier ${TOOL_TIER}"
        if [[ "$READ_ONLY" == "true" ]]; then
            CLAUDE_ARGS="${CLAUDE_ARGS} --read-only"
        fi

        claude mcp add --transport stdio --scope user \
            --env "GOOGLE_OAUTH_CLIENT_ID=${GOOGLE_CLIENT_ID}" \
            --env "GOOGLE_OAUTH_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}" \
            google-workspace -- ${CLAUDE_ARGS} 2>/dev/null && \
            success "Claude Code configured" || \
            warn "Could not configure Claude Code automatically. Add it manually."
    else
        warn "Claude Code CLI not found. Skipping."
        info "Install Claude Code first, then run:"
        echo "  claude mcp add --transport stdio --scope user \\"
        echo "    --env GOOGLE_OAUTH_CLIENT_ID=<your-id> \\"
        echo "    --env GOOGLE_OAUTH_CLIENT_SECRET=<your-secret> \\"
        echo "    google-workspace -- uvx workspace-mcp --tool-tier ${TOOL_TIER}"
    fi
fi

# ============================================================================
# STEP 6: Create credentials directory
# ============================================================================

mkdir -p "$CREDENTIALS_DIR"
success "Credentials directory ready: ${CREDENTIALS_DIR}"

# ============================================================================
# STEP 7: Summary
# ============================================================================

header "Setup Complete"

echo -e "${GREEN}${BOLD}Google Workspace MCP is configured!${NC}\n"
echo -e "  ${BOLD}Access level:${NC}  ${ACCESS_DESC}"
echo -e "  ${BOLD}Tool tier:${NC}     ${TOOL_TIER}"
echo -e "  ${BOLD}Config file:${NC}   ${OPENCODE_CONFIG}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo ""
echo "  1. Start OpenCode in any project directory:"
echo "     ${CYAN}opencode${NC}"
echo ""
echo "  2. The first time you use a Google Workspace tool, a browser"
echo "     window will open asking you to sign in to your Google account"
echo "     and grant permissions. This only happens once."
echo ""
echo "  3. Try asking:"
echo "     ${CYAN}\"Show me my unread emails\"${NC}"
echo "     ${CYAN}\"What's on my calendar this week?\"${NC}"
echo "     ${CYAN}\"Search my Google Drive for project proposals\"${NC}"
echo ""

if [[ "$READ_ONLY" == "true" ]]; then
    info "You selected read-only mode. To enable write access later,"
    info "re-run this script and choose 'Full access'."
fi

echo ""
echo -e "${BOLD}Troubleshooting:${NC}"
echo "  • If authentication fails, check your OAuth credentials"
echo "  • Ensure the required APIs are enabled in Google Cloud Console"
echo "  • Re-run this script to reconfigure: ${CYAN}bash ~/.config/opencode/scripts/setup-google-workspace.sh${NC}"
echo ""
