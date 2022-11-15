# See a bunch of other options at https://bitbucket.org/durdn/cfg/src/master/.bashrc

# Set local aliases here. You probably don't want to check this file into source control.
if [ -f ~/.local_aliases.sh ]; then
    . ~/.local_aliases.sh
fi

# Main utility function for handling the dotfiles
function dotfile {
   /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
}

# Aliases [[

  alias k=kubectl

# ]]

# Utilities[[

  # Simple bookmarking [[
  if [ -d "$HOME/.bookmarks" ]; then
    export CDPATH="$CDPATH:$HOME/.bookmarks:/"
    alias j="cd -P"

    function bookmark(){
      if [ $# -lt 2 ]
        then
          echo "Usage: $funcstack[1] <abs-path> <alias>"
          return
      fi
      ln -s $1 $HOME/.bookmarks/"@$2"
    }

    alias b=bookmark
  fi
  # ]]
# ]]

# Linux specific config [[
if [ $(uname) = "Linux" ]; then
  
  # Set up a pomodoro helper
  function tomate(){
		 ({sleep $((15 * 60)); notify-send "Tomate 🍅" "Your tomate is ready. Take a break or set up a new tomate"} > /dev/null &)
	}

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
# ]]

# OSX specific config [[
if [ $(uname) = "Darwin" ]; then
	# Set up a pomodoro helper
  function tomate(){
		((sleep $((15 * 60)); osascript -e 'display notification "Take a break or set up a new tomate" with title "Tomate 🍅" subtitle "Your tomate is done" sound name "Purr"') > /dev/null 2>&1 &)
	}
fi
# ]]
