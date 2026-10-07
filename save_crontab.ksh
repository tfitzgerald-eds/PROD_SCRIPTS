#!/bin/ksh
exec 2>/tmp/$(basename $0 .ksh).$LOGNAME.trace.$(date +%Y%m%d)
set -x

MAX=30

# --- Setup Backup Directory ---
# Create the directory if it doesn't exist
[ -d /etl/save_crontabs ] || mkdir -p /etl/save_crontabs

# Move into the directory; exit if it fails to prevent backing up in the wrong place
cd /etl/save_crontabs || exit 1

# --- 1. Prepare Space ---
# Remove the oldest file first so the ripple has a "slot" to move into.
if [ -f "crontab.$MAX" ]; then
    rm "crontab.$MAX"
fi

# --- 2. Ripple Backups ---
# ls -rt sorts by modification time (oldest first).
ls -rt crontab.* 2>/dev/null | while read CTFILE
do
    # Extract the extension
    NUM_EXT=$(echo "$CTFILE" | awk -F. '{print $NF}')

    # Check if the extension is numeric using ksh-compliant globbing
    # +([0-9]) is the ksh equivalent of the regex ^[0-9]+$
    if [[ "$NUM_EXT" == +([0-9]) ]]; then
        NEW_NUM=$((NUM_EXT + 1))
        mv "$CTFILE" "crontab.$NEW_NUM"
    fi
done

# --- 3. Create Today's Backup ---
# Capture the current crontab and save it as the new '0' version
crontab -l > crontab.0
