#!/bin/zsh
# Removes the launch.sh bindkey block from ~/.local_aliases.sh (idempotent)
ALIASES="${HOME}/.local_aliases.sh"

[[ -f "$ALIASES" ]] || exit 0
grep -q "# @managed: launch-bindkey" "$ALIASES" || exit 0

sed -i '' '/^# @managed: launch-bindkey/,/^# @end: launch-bindkey/d' "${ALIASES:A}"

echo "launch bindkey removed from ${ALIASES}"
