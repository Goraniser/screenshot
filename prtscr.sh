#!/bin/bash
TITLE="Screenshot"
MSGBODY=""
ERR=""

DISPLAY=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
FILENAME="${DISPLAY}_${TIMESTAMP}.png"
PICTUREDIR="$HOME/Pictures/Screenshots"
mkdir -p "$PICTUREDIR"

FULLPATH="$PICTUREDIR/$FILENAME"

if [[ -z "$1" ]]; then
    GEOMETRY=$(slurp 2>/dev/null)
    if [[ -z "$GEOMETRY" ]]; then
        notify-send -t 1500 "$TITLE" "Cancelled"
        exit 0
    fi

    grim -g "$GEOMETRY" -c "$FULLPATH"

elif [[ "$1" == "fullscr" ]]; then
    grim -c "$FULLPATH"

else
    notify-send -t 1500 "$TITLE" "Bad argument $1"
    exit 1
fi

if wl-copy < "$FULLPATH"; then
    MSGBODY+="Copied to wl-clipboard\n"
else
    ERR=$(wl-copy < "$FULLPATH" 2>&1)
    MSGBODY+="wl-clipboard?\n$ERR\n"
fi

DEVICE=$(kdeconnect-cli -a --id-name-only | head -n 1)

if [[ -n $DEVICE ]]; then
    DEVICEUUID=$(echo "$DEVICE" | cut -d' ' -f1)
    CONNECT=$(echo "$DEVICE" | cut -d' ' -f2-)

    if kdeconnect-cli --device "${DEVICEUUID}" --share "$FULLPATH" >/dev/null; then
        MSGBODY+="Sent to $CONNECT"
    else
        ERR=$(kdeconnect-cli --device ${DEVICEUUID} --share "$FULLPATH" 2>&1)
	MSGBODY+="kdeconnect-cli?\n$ERR"
    fi
else
    MSGBODY+="Sent to nowhere lmao"
fi

if [[ -z $ERR ]]; then
    notify-send -i /usr/share/icons/Adwaita/symbolic/legacy/applets-screenshooter-symbolic.svg \
	        -h string:x-canonical-private-synchronous:prtscr \
		-t 3000 \
		"$TITLE" "$(echo -e "$MSGBODY")"
else
    notify-send -u critical \
	        -i dialog-error-symbolic \
		-h string:x-canonical-private-synchronous:prtscr \
		"$TITLE" "$(echo -e "$MSGBODY")"
fi
