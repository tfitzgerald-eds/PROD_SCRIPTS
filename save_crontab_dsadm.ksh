#!/bin/ksh
# Trace setup
TRACE_FILE="/tmp/$(basename $0 .ksh).$LOGNAME.trace.$(date +%Y%m%d)"
exec 2>"$TRACE_FILE"
set -x

MAX=28
BACKUP_DIR="/etl/save_crontabs_dsadm"

# Ensure directory exists
[ -d "$BACKUP_DIR" ] || mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR" || exit 1

# 1. Ripple backups (Oldest to Newest)
# We only target files named 'crontab.' followed by numbers
for CTFILE in $(ls -rt crontab.[0-9]* 2>/dev/null)
do
    # Extract the suffix (the number)
    NUM=$(echo "$CTFILE" | awk -F. '{print $NF}')
    
    # Validation: Ensure NUM is actually an integer
    if [[ "$NUM" == +([0-9]) ]]; then
        NEW_NUM=$((NUM + 1))
        mv "$CTFILE" "crontab.$NEW_NUM"
    fi
done

# 2. Capture today's crontab
crontab -l > crontab.0

# 3. Clean up the oldest file beyond the MAX limit
# This removes the file that was pushed to MAX during the ripple
if [ -s "crontab.$MAX" ]; then
    rm "crontab.$MAX"
fi
