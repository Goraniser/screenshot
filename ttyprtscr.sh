#!/bin/sh
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
FILENAME="tty_${TIMESTAMP}.png"
TMPFILENAME="tty_${TIMESTAMP}.ppm"
SAVETO="$HOME/Pictures/Screenshots"

PRINTMSG() {
    TITLE="PrtScr"
    MSGBODY="$1"
    ISIMPORTANT="$2"

    if [ -z "$ISIMPORTANT" ]; then
	printf "%s: %s\n" "${TITLE}" "${MSGBODY}" >&2
    else
	printf "\e[1;31m%s: %s\e[0m\n" "${TITLE}" "${MSGBODY}" >&2
    fi
}

HASDEPENDENCIES() {
    for cmd in fbcat magick tailscale hostname awk grep; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
	    PRINTMSG "?\`${cmd}\' program" 1
	    PRINTMSG "Requires: fbcat imagemagick tailscale inetutils awk grep"
	    exit 1
	fi
    done
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
    target_file="$1"

    if ! tailscale status >/dev/null 2>&1; then
	PRINTMSG "?Tailscale" 1
	return 0
    fi

    CURHOST=$(hostname)
    TARGETDEV=$(tailscale status | grep -v -i "$CURHOST" | head -n 1 | awk '{print $2}')

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
HASDEPENDENCIES

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

rm -f "$TMPPATH"
PRINTMSG "Cleaned $TMPPATH up"

TAILDROP_SEND "$FULLPATH"
