# Default values
PKG ?= */
TARGET ?= $$HOME

restow:
	stow --verbose --no-folding --target=$(TARGET) --restow $(PKG)
	@[ -x local/local/bin/add-bindkey.sh ] && zsh local/local/bin/add-bindkey.sh || true

delete:
	@[ -x local/local/bin/remove-bindkey.sh ] && zsh local/local/bin/remove-bindkey.sh || true
	stow --verbose --no-folding --target=$(TARGET) --delete $(PKG)
