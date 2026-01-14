#!/usr/bin/env bash
#
# Dotfiles installer script
# Installs Homebrew and required utilities
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

DRY_RUN=false

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
dry_run() { echo -e "${CYAN}[DRY-RUN]${NC} $1"; }

show_usage() {
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -n, --dry-run    Show what would be installed without actually installing"
    echo "  -h, --help       Show this help message"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if running on macOS or Linux
OS="$(uname)"
if [ "$OS" != "Darwin" ] && [ "$OS" != "Linux" ]; then
    error "Unsupported operating system: $OS"
    exit 1
fi

if [ "$DRY_RUN" = true ]; then
    warn "Running in dry-run mode - no changes will be made"
    echo ""
fi

info "Detected OS: $OS"

# =============================================================================
# Homebrew
# =============================================================================
install_homebrew() {
    if command -v brew &> /dev/null; then
        success "Homebrew already installed"
    else
        if [ "$DRY_RUN" = true ]; then
            dry_run "Install Homebrew"
        else
            info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            # Add brew to PATH for this session
            if [ "$OS" = "Darwin" ]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            else
                eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
            fi
            success "Homebrew installed"
        fi
    fi
}

# =============================================================================
# Brew packages
# =============================================================================
BREW_PACKAGES=(
    stow           # For managing dotfiles
    pyenv          # Python version manager
    nvm            # Node version manager
    terraform      # Infrastructure as code
    pnpm           # Fast Node package manager
    autojump       # Quick directory navigation
    tmux           # Terminal multiplexer
    kubectl        # Kubernetes CLI
    jq             # JSON processor
)

# macOS-only packages
BREW_PACKAGES_MACOS=(
    google-cloud-sdk  # Google Cloud CLI
    yabai             # Tiling window manager
    skhd              # Hotkey daemon
)

# macOS-only casks (GUI apps)
BREW_CASKS_MACOS=(
)

install_brew_packages() {
    info "Installing brew packages..."

    for pkg in "${BREW_PACKAGES[@]}"; do
        # Special handling for nvm - check if command exists first
        if [ "$pkg" = "nvm" ]; then
            if command -v nvm &> /dev/null || [ -d "$HOME/.nvm" ]; then
                success "nvm already installed"
            else
                if [ "$DRY_RUN" = true ]; then
                    dry_run "brew install nvm"
                else
                    info "Installing nvm..."
                    brew install nvm
                fi
            fi
        elif brew list "$pkg" &> /dev/null; then
            success "$pkg already installed"
        else
            if [ "$DRY_RUN" = true ]; then
                dry_run "brew install $pkg"
            else
                info "Installing $pkg..."
                brew install "$pkg"
            fi
        fi
    done

    # macOS-only packages
    if [ "$OS" = "Darwin" ]; then
        for pkg in "${BREW_PACKAGES_MACOS[@]}"; do
            if brew list "$pkg" &> /dev/null; then
                success "$pkg already installed"
            else
                if [ "$DRY_RUN" = true ]; then
                    dry_run "brew install $pkg"
                else
                    info "Installing $pkg..."
                    brew install "$pkg"
                fi
            fi
        done

        # Casks
        for cask in "${BREW_CASKS_MACOS[@]}"; do
            if brew list --cask "$cask" &> /dev/null; then
                success "$cask already installed"
            else
                if [ "$DRY_RUN" = true ]; then
                    dry_run "brew install --cask $cask"
                else
                    info "Installing $cask..."
                    brew install --cask "$cask"
                fi
            fi
        done
    fi
}

# =============================================================================
# Oh My Zsh
# =============================================================================
install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        success "Oh My Zsh already installed"
    else
        if [ "$DRY_RUN" = true ]; then
            dry_run "Install Oh My Zsh"
        else
            info "Installing Oh My Zsh..."
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            success "Oh My Zsh installed"
        fi
    fi
}

# =============================================================================
# SDKMAN (Java version manager)
# =============================================================================
install_sdkman() {
    if [ -d "$HOME/.sdkman" ]; then
        success "SDKMAN already installed"
    else
        if [ "$DRY_RUN" = true ]; then
            dry_run "Install SDKMAN"
        else
            info "Installing SDKMAN..."
            curl -s "https://get.sdkman.io" | bash
            success "SDKMAN installed"
        fi
    fi
}

# =============================================================================
# JBang (Java scripting)
# =============================================================================
install_jbang() {
    if command -v jbang &> /dev/null; then
        success "JBang already installed"
    else
        if [ "$DRY_RUN" = true ]; then
            dry_run "Install JBang"
        else
            info "Installing JBang..."
            curl -Ls https://sh.jbang.dev | bash -s - app setup
            success "JBang installed"
        fi
    fi
}

# =============================================================================
# Rust/Cargo
# =============================================================================
install_rust() {
    if command -v cargo &> /dev/null; then
        success "Rust/Cargo already installed"
    else
        if [ "$DRY_RUN" = true ]; then
            dry_run "Install Rust/Cargo"
        else
            info "Installing Rust..."
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source "$HOME/.cargo/env"
            success "Rust installed"
        fi
    fi
}

# =============================================================================
# Vim-Plug (Vim plugin manager)
# =============================================================================
install_vim_plug() {
    if [ -f "$HOME/.vim/autoload/plug.vim" ]; then
        success "Vim-Plug already installed"
    else
        if [ "$DRY_RUN" = true ]; then
            dry_run "Install Vim-Plug"
        else
            info "Installing Vim-Plug..."
            curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
                https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
            success "Vim-Plug installed"
        fi
    fi
}

# =============================================================================
# Tmuxinator
# =============================================================================
install_tmuxinator() {
    if command -v tmuxinator &> /dev/null; then
        success "Tmuxinator already installed"
    else
        if [ "$DRY_RUN" = true ]; then
            dry_run "gem install tmuxinator"
        else
            info "Installing Tmuxinator..."
            gem install tmuxinator
            success "Tmuxinator installed"
        fi
    fi
}

# =============================================================================
# Leetcode CLI (optional - requires npm)
# =============================================================================
install_leetcode_cli() {
    if command -v leetcode &> /dev/null; then
        success "Leetcode CLI already installed"
    else
        if [ "$DRY_RUN" = true ]; then
            dry_run "npm install -g leetcode-cli (optional)"
        else
            warn "Leetcode CLI not installed. To install manually:"
            echo "    npm install -g leetcode-cli"
        fi
    fi
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo ""
    echo "========================================"
    echo "  Dotfiles Dependency Installer"
    echo "========================================"
    echo ""

    install_homebrew
    install_brew_packages
    install_oh_my_zsh
    install_sdkman
    install_jbang
    install_rust
    install_vim_plug
    install_tmuxinator
    install_leetcode_cli

    echo ""
    echo "========================================"
    if [ "$DRY_RUN" = true ]; then
        success "Dry-run complete!"
    else
        success "Installation complete!"
    fi
    echo "========================================"
    echo ""

    if [ "$DRY_RUN" = false ]; then
        info "Next steps:"
        echo "  1. Restart your terminal or run: source ~/.zshrc"
        echo "  2. Run 'make restow' to install dotfiles"
        echo "  3. Run ':PlugInstall' in vim to install plugins"
        echo ""
    fi

    if [ "$OS" = "Darwin" ]; then
        warn "For yabai/skhd to work, you may need to:"
        echo "  - Enable accessibility permissions in System Preferences"
        echo "  - Start services: yabai/skhd --install-service" 
    fi
}

main "$@"
