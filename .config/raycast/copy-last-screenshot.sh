#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Copy Last Screenshot
# @raycast.mode silent
# @raycast.packageName Clipboard Utils
# @raycast.icon 📸

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"

# Find most recent screenshot (just the filename)
LAST_SCREENSHOT=$(/bin/ls -t "$SCREENSHOT_DIR"/Screenshot*.png 2>/dev/null | head -1)

if [[ -z "$LAST_SCREENSHOT" ]]; then
    echo "No screenshot found"
    exit 1
fi

# Copy image to clipboard (not path - actual image data)
osascript -e "set the clipboard to (read (POSIX file \"$LAST_SCREENSHOT\") as «class PNGf»)"

echo "Copied: $(basename "$LAST_SCREENSHOT")"

