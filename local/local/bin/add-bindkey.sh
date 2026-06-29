#!/bin/zsh
# Adds the launch.sh bindkey block to ~/.local_aliases.sh (idempotent)
ALIASES="${HOME}/.local_aliases.sh"
MARKER="# @managed: launch-bindkey"

grep -q "$MARKER" "$ALIASES" 2>/dev/null && exit 0

cat >> "$ALIASES" <<'EOF'

# @managed: launch-bindkey
_launch_widget() {
  zle -I
  "${HOME}/local/bin/launch.sh"
  zle reset-prompt
}
zle -N _launch_widget
bindkey '\er' _launch_widget
# @end: launch-bindkey
EOF

echo "launch bindkey added to ${ALIASES}"
