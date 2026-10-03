#!/bin/bash
# <xbar.title>Displays</xbar.title>
# <xbar.desc>Disconnects and reconnects displays with displayctl, as if unplugging them.</xbar.desc>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
#
# Needs displayctl (dotfiles: local/local/displayctl, install with its build.sh).
#
# The menu bar icon shows one or two screens depending on how many displays are
# on. The menu has a section per display, whose icon shows whether it is on,
# with "Connect" or "Disconnect" and "Set as Main Display", which moves the
# menu bar to it (permanently). "Brightness…" opens a panel with a slider per
# display (brightness-panel, built along with displayctl); "Full Brightness"
# sets every display that is on to 100%.
# The items call this script back with the action and the display's selector,
# so that a failure (e.g. refusing to switch off the last display) shows up as
# a notification instead of disappearing (they run with terminal=false).

DISPLAYCTL="$HOME/.local/bin/displayctl"
PANEL="$HOME/.local/bin/brightness-panel"
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

# The panel stays open while it's used, so start it in the background rather
# than keep SwiftBar waiting.
if [[ ${1:-} == panel ]]; then
    "$PANEL" >/dev/null 2>&1 &
    exit 0
fi

notify() {
    local text="${2//\"/\'}"
    osascript -e "display notification \"$text\" with title \"$1\""
}

if [[ ${1:-} == full ]]; then
    failed=""
    while IFS=$'\t' read -r _ _ _ _ _ status _ name _ _ selector; do
        [[ $status == active* ]] || continue
        "$DISPLAYCTL" brightness "$selector" 100 >/dev/null 2>&1 || failed="$failed${failed:+, }$name"
    done < <("$DISPLAYCTL" list --tsv | tail -n +2)
    [[ -n $failed ]] && notify "Full brightness failed" "$failed"
    exit 0
fi

if [[ $# -ge 2 ]]; then
    if ! out="$("$DISPLAYCTL" "$@" 2>&1)"; then
        notify "displayctl $1 failed" "$out"
    fi
    exit 0
fi

if [[ ! -x $DISPLAYCTL ]]; then
    error="displayctl not installed, run ~/local/displayctl/build.sh"
elif ! displays="$("$DISPLAYCTL" list --tsv 2>&1)"; then
    error="${displays//$'\n'/ }"
fi

if [[ -n ${error:-} ]]; then
    # An inline :symbol: in the title is tinted by sfcolor; sfimage= is not.
    echo ":display.trianglebadge.exclamationmark: | sfcolor=#FF3B30 sfsize=16"
    echo "---"
    echo "${error//|/-} | color=#FF3B30"
    exit 0
fi

items=()
on=0
# displayctl refuses to disconnect the last active display or the built-in one
# (without --force), so those don't get a Disconnect item.
active=$(tail -n +2 <<<"$displays" | cut -f6 | grep -c '^active')
while IFS=$'\t' read -r _ _ _ _ builtin status _ name _ _ selector; do
    action="bash=\"$SELF\" param2=$selector terminal=false refresh=true"
    case $status in
        disabled) items+=("---" "${name//|/-} | sfimage=rectangle.dashed" "Connect | param1=connect $action") ;;
        offline) items+=("---" "${name//|/-} (offline) | sfimage=rectangle.dashed" "Connect | param1=connect $action") ;;
        *)
            on=$((on + 1))
            items+=("---" "${name//|/-} | sfimage=display")
            others=$active
            [[ $status == active* ]] && others=$((active - 1))
            if [[ $builtin == no ]] && (( others > 0 )); then
                items+=("Disconnect | param1=disconnect $action")
            fi
            if [[ $status == *main* ]]; then
                items+=("Main Display | checked=true")
            elif [[ $status == active ]]; then
                items+=("Set as Main Display | param1=main $action")
            fi
            ;;
    esac
done < <(tail -n +2 <<<"$displays")

# sfimage= renders as a template image, so it matches the other menu bar icons.
if (( on > 1 )); then
    echo " | sfimage=display.2"
else
    echo " | sfimage=display"
fi
printf '%s\n' "${items[@]}"
echo "---"
[[ -x $PANEL ]] && echo "Brightness… | bash=\"$SELF\" param1=panel terminal=false sfimage=sun.max"
echo "Full Brightness | bash=\"$SELF\" param1=full terminal=false sfimage=sun.max.fill"
echo "Show displays | bash=\"$DISPLAYCTL\" param1=list terminal=true sfimage=list.bullet"
