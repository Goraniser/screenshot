#!/bin/bash
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
FILENAME="tty_${TIMESTAMP}.png"
TMPFILENAME="tty_${TIMESTAMP}.ppm"
SAVETO="$HOME/Pictures/Screenshots"

PRINTMSG() {
    TITLE="PrtScr"
    MSGBODY="$1"
    ISIMPORTANT="$2"

    if [ -z "$ISIMPORTANT" ]; then
	printf "${TITLE}: ${MSGBODY}\n" >&2
    else
	printf "\033[1;31m${TITLE}: ${MSGBODY}\033[0m\n" >&2
    fi
}

ISTTY() {
    if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
	PRINTMSG "GUI Session" 1
	exit 1
    fi
    
    case "$(tty)" in
	/dev/tty[0-9]*)
	    :
	    ;;
	
	*)
	    PRINTMSG "!tty" 1
	    exit 1
    esac
}

TAILDROP_SEND() {
    local target_file="$1"

    if ! tailscale status >/dev/null 2>&1; then
	PRINTMSG "?Tailscale" 1
	return 1
    fi

    TARGETDEV=$(tailscale status | grep -v -i "$HOSTNAME" | head -n 1 | awk '{print $2}')

    if [ -z "$TARGETDEV" ]; then
	PRINTMSG "?Phone"
	return 1
    fi

    PRINTMSG "Sending to $TARGETDEV via Taildrop"

    if tailscale file cp "$target_file" "${TARGETDEV}:"; then
	PRINTMSG "Sent to $TARGETDEV"
	return 0
    else
	PRINTMSG "Failed to send to $TARGETDEV" 1
	return 0
    fi
}

ISTTY

mkdir -p "$SAVETO"
FULLPATH="$SAVETO/$FILENAME"
TMPPATH="/tmp/$TMPFILENAME"

if ! fbcat > "$TMPPATH" 2>/dev/null; then
    PRINTMSG "?\"video\" group" 1
    PRINTMSG "Requires: doas usermod -aG video $USER"
    exit 1
fi
PRINTMSG "PPM at $TMPPATH"

if ! magick $TMPPATH $FULLPATH; then
    PRINTMSG "!Imagemagick" 1
    rm -f "$TMPPATH"
    exit 1
fi
PRINTMSG "File at $FULLPATH"

rm -f $TMPPATH
PRINTMSG "Cleaned $TMPPATH up"

TAILDROP_SEND "$FULLPATH"
