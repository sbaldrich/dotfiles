# Load brew autocompletions
FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

# I don't like omz to take over my .zshrc file, so I keep that config separate.
[[ -s "$HOME/.oh-my-zsh.sh" ]] && source "$HOME/.oh-my-zsh.sh"

## sdkman
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

## pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

## nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

## google-cloud-sdk
source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
autoload -Uz compinit
zstyle ':completion:*' menu select
fpath+=~/.zfunc


autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end


# Leetcode related setup
eval "$(leetcode completions)"
alias leet='tmuxinator start leetcode $1'

alias jat='$HOME/ws/bin/run-unit-tests.sh'
alias jax='java $1'


# Created by `pipx` on 2025-09-24 21:36:08
export PATH="$PATH:$HOME/.local/bin"

# Unset the jo override that autojump created
unset -f jo

# Add JBang to environment
alias j!=jbang
export PATH="$HOME/.jbang/bin:$PATH"
