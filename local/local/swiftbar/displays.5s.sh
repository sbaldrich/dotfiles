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
# with "Connect" or "Disconnect", and "Set as Main Display", which moves the
# menu bar to it (permanently).
# The items call this script back with the action and the display's selector,
# so that a failure (e.g. refusing to switch off the last display) shows up as
# a notification instead of disappearing (they run with terminal=false).

DISPLAYCTL="$HOME/.local/bin/displayctl"
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

if [[ $# -eq 2 ]]; then
    if ! out="$("$DISPLAYCTL" "$1" "$2" 2>&1)"; then
        out="${out//\"/\'}"
        osascript -e "display notification \"$out\" with title \"displayctl $1 failed\""
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
while IFS=$'\t' read -r _ _ _ _ _ status _ name _ selector; do
    action="bash=\"$SELF\" param2=$selector terminal=false refresh=true"
    case $status in
        disabled) items+=("---" "${name//|/-} | sfimage=rectangle.dashed" "Connect | param1=connect $action") ;;
        offline) items+=("---" "${name//|/-} (offline) | sfimage=rectangle.dashed" "Connect | param1=connect $action") ;;
        *)
            on=$((on + 1))
            items+=("---" "${name//|/-} | sfimage=display" "Disconnect | param1=disconnect $action")
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
echo "Show displays | bash=\"$DISPLAYCTL\" param1=list terminal=true sfimage=list.bullet"
