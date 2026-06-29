#!/bin/zsh

LAUNCHER_DIR="${HOME}/local/scripts"
typeset -A SCRIPTS

for script in ${LAUNCHER_DIR}/*.sh; do
  label=$(grep -m1 '^# @label ' "$script" | sed 's/^# @label //')
  [[ -z "$label" ]] && label=$(basename "$script" .sh | tr '-' ' ')
  SCRIPTS[$label]="$script"
done

CHOICE=$(printf '%s\n' "${(k)SCRIPTS[@]}" | sort | fzf --border --margin 10% --padding 1 --height 10% )

[[ -n "$CHOICE" ]] && zsh "${SCRIPTS[$CHOICE]}"
