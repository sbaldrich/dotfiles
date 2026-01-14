# Dotfiles

I used to have a dedicated `dotfile` command to deal with dotfiles. However, I find `stow` to be a better option for me.
See how it works [here](https://blog.sbaldrich.dev/blog/2021-02-07-easy-dotfiles-with-stow).

## Installation

### Automated Setup (Recommended)

Run the installer script to automatically install Homebrew and all required dependencies:

```shell
./install.sh
```

#### Dry-Run Mode

To preview what will be installed without making any changes:

```shell
./install.sh --dry-run
# or
./install.sh -n
```

This will show all the packages and tools that would be installed, which is useful for understanding dependencies before committing to the installation.

## Setup

Either use `stow` directly with a package:

```shell
stow --verbose --target=$$HOME -n --restow zsh
```

Or just use make to set everything up:

```shell
make restow
```

### Local Customization

To add personal aliases and configurations that shouldn't be version controlled:

```shell
cd local
cp .local_aliases.sh.example .local_aliases.sh
# Edit .local_aliases.sh with your personal settings
```

Both bash and zsh configurations will automatically source this file if it exists.

## Uninstalling

Use the `make delete` command.

## Notes

* The vim configuration uses `vim-plug` for plugin management. The `install.sh` script automatically installs it, or you can follow [these instructions](https://github.com/junegunn/vim-plug#vim) to install it manually.
* After installation, run `:PlugInstall` in vim to install all configured plugins.