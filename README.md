# Dotfiles

I used to have a dedicated `dotfile` command to deal with dotfiles. However, I find `stow` to be a better option for me. 
See how it works [here](https://blog.sbaldrich.dev/blog/2021-02-07-easy-dotfiles-with-stow).

## Setup

Either use `stow` directly with a package:

```shell
stow --verbose --target=$$HOME -n --restow zsh
```

Or just use make to set everything up:

```shell
make restow
```

## Uninstalling

Use the `make delete` command.

## Notes

* The vim configuration assumes you've installed `vim-plug`. To do so you can follow [these instructions](https://github.com/junegunn/vim-plug#vim)