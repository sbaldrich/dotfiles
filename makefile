# Default values
PKG ?= */
TARGET ?= $$HOME

# Ensure Homebrew bin is on PATH (Apple Silicon: /opt/homebrew, Intel: /usr/local)
BREW_PREFIX := $(shell [ -d /opt/homebrew ] && echo /opt/homebrew || echo /usr/local)
export PATH := $(BREW_PREFIX)/bin:$(PATH)

restow:
	stow --verbose --no-folding --target=$(TARGET) --restow $(PKG)
	@[ -x local/local/bin/add-bindkey.sh ] && zsh local/local/bin/add-bindkey.sh || true

delete:
	@[ -x local/local/bin/remove-bindkey.sh ] && zsh local/local/bin/remove-bindkey.sh || true
	stow --verbose --no-folding --target=$(TARGET) --delete $(PKG)
