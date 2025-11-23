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

DATA_DIR="$SOURCE"
DAILY="$DEST_BASE"
WEEKLY="$WEEKLY_BASE"

function check_permissions() {
    local TEST_DIR="$1"
    if ! [ -r "$TEST_DIR" ]; then
        echo "❌ No permission to read $TEST_DIR, restarting with sudo..."
        exec sudo bash "$0" "$@"
    fi
}

echo "=== Immich Snapshot Restorer ==="
echo
echo "Available snapshots (daily):"
ls "$DAILY" || true
echo
echo "Available snapshots (weekly):"
ls "$WEEKLY" || true
echo

read -rp "Enter the date of the snapshot you want to restore (e.g., 2025-01-17): " SNAP

if [ -d "$DAILY/$SNAP" ]; then
    SRC="$DAILY/$SNAP"
elif [ -d "$WEEKLY/$SNAP" ]; then
    SRC="$WEEKLY/$SNAP"
else
    echo "❌ ERROR: No snapshot exists with that date."
    exit 1
fi

check_permissions "$SRC"

echo
echo "✔ Snapshot found at: $SRC"
echo

read -rp "Are you sure you want to restore this snapshot? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

echo
echo "🟦 Stopping Immich..."
cd "$IMMICH_DIR"
docker compose down

echo "🟨 Renaming current folder to data.old..."
mv "$DATA_DIR" "$DATA_DIR.old.$(date +%s)" || true
mkdir -p "$DATA_DIR"

echo "🟩 Restoring snapshot with rsync (progress enabled)..."
rsync -a --info=progress2 "$SRC/" "$DATA_DIR/"

echo "🟢 Adjusting permissions for user $USER_OWNER..."
chown -R "$USER_OWNER":"$USER_OWNER" "$DATA_DIR"

echo "🟢 Starting Immich..."
docker compose up -d

echo
echo "🎉 Restoration completed."
echo "Immich is restored to snapshot: $SNAP"
echo