# Load brew autocompletions
if command -v brew &> /dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

# I don't like omz to take over my .zshrc file, so I keep that config separate.
[[ -s "$HOME/.oh-my-zsh.sh" ]] && source "$HOME/.oh-my-zsh.sh"

# Load shared aliases and configurations
[[ -s "$HOME/.common_aliases.sh" ]] && source "$HOME/.common_aliases.sh"

# Load local aliases (user-specific, not version controlled)
[[ -s "$HOME/.local_aliases.sh" ]] && source "$HOME/.local_aliases.sh"

## pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv &> /dev/null && eval "$(pyenv init -)"

## nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

## google-cloud-sdk
if command -v brew &> /dev/null; then
  local gcloud_path="$(brew --prefix)/share/google-cloud-sdk"
  [ -f "$gcloud_path/path.zsh.inc" ] && source "$gcloud_path/path.zsh.inc"
  [ -f "$gcloud_path/completion.zsh.inc" ] && source "$gcloud_path/completion.zsh.inc"
fi
autoload -Uz compinit
zstyle ':completion:*' menu select
fpath+=~/.zfunc


autoload -U +X bashcompinit && bashcompinit
command -v terraform &> /dev/null && complete -o nospace -C "$(command -v terraform)" terraform

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end


# Leetcode related setup
alias leet='tmuxinator start leetcode $1'

alias jat='$HOME/ws/bin/run-unit-tests.sh'


# Created by `pipx` on 2025-09-24 21:36:08
export PATH="$PATH:$HOME/.local/bin"

# Unset the jo override that autojump created
unset -f jo

## sdkman
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
