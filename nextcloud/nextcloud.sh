#!/bin/bash
set -euo pipefail

ENV_FILE="/route_to_env_file/.env"

if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
else
    echo "❌ File $ENV_FILE not found"
    exit 1
fi

# Current and yesterday's date
DATE=$(date +%F)
YESTERDAY=$(date -d "yesterday" +%F)

# Destinations
DEST="$DEST_BASE/$DATE"
PREV="$DEST_BASE/$YESTERDAY"
WEEKLY_DEST="$WEEKLY_BASE/$DATE"

echo "[$DATE] Starting snapshot backup of $SERVICE_NAME" >> "$LOG"

# 🔒 Verify that disks are mounted
for MNT in /mnt/hdd2 /mnt/hdd3; do
    if ! mountpoint -q "$MNT"; then
        echo "[$DATE] ERROR: $MNT is not mounted" >> "$LOG"
        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
            -d chat_id="$CHAT_ID" \
            -d text="❌ ERROR: Disk at $MNT is not mounted. $SERVICE_NAME backup aborted on $DATE"
        exit 1
    fi
done

# Create daily destination folder
mkdir -p "$DEST"

# Daily backup with hardlinks if previous snapshot exists
if [ -d "$PREV" ]; then
    rsync -a --delete --link-dest="$PREV" "$SOURCE" "$DEST" >> "$LOG" 2>&1
else
    rsync -a --delete "$SOURCE" "$DEST" >> "$LOG" 2>&1
fi

echo "[$DATE] Daily snapshot of $SERVICE_NAME completed at $DEST" >> "$LOG"

# Keep only the latest daily backups
cd "$DEST_BASE" || exit
count=$(ls -1d 20* 2>/dev/null | wc -l || true)
if [ "$count" -gt "$DAILY_BACKUPS" ]; then
    ls -1d 20* | sort | head -n -"${DAILY_BACKUPS}" | while read -r dir; do
        echo "[$(date +%F)] Deleting old snapshot: $dir" >> "$LOG"
        rm -rf "$dir"
    done
fi

# Weekly backup on Sundays (day 7)
if [ "$(date +%u)" -eq 7 ]; then
    mkdir -p "$WEEKLY_DEST"
    rsync -a --delete "$SOURCE" "$WEEKLY_DEST" >> "$LOG" 2>&1
    echo "[$DATE] Weekly snapshot of $SERVICE_NAME saved to $WEEKLY_DEST" >> "$LOG"
fi

# Daily Telegram notification
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="✅ Daily backup of $SERVICE_NAME completed successfully on $DATE"

# Weekly Telegram notification (Sundays only)
if [ "$(date +%u)" -eq 7 ]; then
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="✅ Weekly backup of $SERVICE_NAME completed successfully on $DATE"
fi

# Keep only the latest weekly backups
cd "$WEEKLY_BASE" || exit
count=$(ls -1d 20* 2>/dev/null | wc -l || true)
if [ "$count" -gt "$WEEKLY_BACKUPS" ]; then
    ls -1d 20* | sort | head -n -"${WEEKLY_BACKUPS}" | while read -r dir; do
        echo "[$(date +%F)] Deleting old weekly snapshot: $dir" >> "$LOG"
        rm -rf "$dir"
    done
fi