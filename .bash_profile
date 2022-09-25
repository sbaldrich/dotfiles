# See a bunch of other options at https://bitbucket.org/durdn/cfg/src/master/.bashrc

# Set local aliases here. You probably don't want to check this file into source control.
if [ -f ~/.local_aliases.sh ]; then
    . ~/.local_aliases.sh
fi

# Aliases

alias k=kubectl

# Linux specific config [[
if [ $(uname) = "Linux" ]; then
  
  # enable color support
  if [ -x /usr/bin/dircolors ]; then
      test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
      alias ls='ls --color'
      alias grep='grep --color'
  fi

  # Add an "alert" alias for long running commands.  Use like so: sleep 10; alert
  alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

  alias ls='ls --color'
  alias ll='ls -l --color'
  alias la='ls -al --color'
  
  # Simpler clipboard usage in scripts
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
  
  # Be a happier vim user (disable using setxkbmap -option)
  alias capsw='setxkbmap -option caps:swapescape'
fi