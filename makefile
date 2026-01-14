# Default values
PKG ?= */
TARGET ?= $$HOME

restow:
	stow --verbose --target=$(TARGET) --restow $(PKG)

delete:
	stow --verbose --target=$(TARGET) --delete $(PKG)
