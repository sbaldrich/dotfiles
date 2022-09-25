# Dotfiles

## Setup

The following commands should be enough to get you started on a new machine. This will setup a new bare repo at `$HOME/.cfg` and setup
the `dotfile` alias for git such that you can use it to manage configuration files.

For more information about this setup, check out this [blog post](https://www.atlassian.com/git/tutorials/dotfiles) by @durdn.

```sh
git clone --bare git@github.com:sbaldrich/dotfiles.git $HOME/.cfg
function dotfile {
   /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
}
mkdir -p .config-backup
dotfile checkout
if [ $? = 0 ]; then
  echo "Checked out config.";
  else
    echo "Backing up pre-existing dot files.";
    config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .config-backup/{}
fi;
dotfile checkout
dotfile config --local status.showUntrackedFiles no
```

## Adding config files

Using the `dotfile` command that is defined somewhere in these dotfiles, you can now modify your configuration and keep track of it using git without having to deal with remembering to symlink.