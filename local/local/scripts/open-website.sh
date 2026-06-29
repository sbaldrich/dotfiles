#!/bin/zsh
# @label Open website

typeset -A sites=(
  "GitHub" "https://github.com"
  "Claude" "https://claude.ai"
)

local choice=$(printf '%s\n' "${(k)sites[@]}" | sort | fzf --border --margin 10% --padding 1 --height 10% --prompt "Open: ")
[[ -n "$choice" ]] && open "${sites[$choice]}"
