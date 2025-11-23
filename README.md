# 💾 Docker Service Snapshot Manager

Efficiently manage incremental backups (snapshots) and restorations for multiple Docker services (such as Immich, Nextcloud, and others) using Bash scripts and `rsync` with hardlinks.  

Robustness, flexibility and easy extensibility are main design goals: add more services by copying scripts and adapting `.env`.

---

## Requirements

- **Bash** (v4.2+ recommended)
- **Docker** (for running target services)
- **rsync** (v3.1+)
- **cron** (for scheduled backups)
- **GNU core utilities**
- **Telegram bot token** (optional, for notifications)<br>
  ℹ️ _Optional: Configure Telegram for real-time backup and restore notifications. See `.env` template below._

---

## Folder Structure

Recommended organization:

```
scripts/
├── immich/
│   ├── immich.sh
│   ├── restore.sh
│   └── .env
├── nextcloud/
│   ├── nextcloud.sh
│   ├── restore.sh
│   └── .env
```

---

## Configuration

To configure each service, add a `.env` file to its specific directory.

Here are sample `.env` templates for Immich and Nextcloud.

### Immich `.env` Example

```dotenv
# Routes
SOURCE="/home/taz/docker/immich/data/"
DEST_BASE="/mnt/hdd2/immich-backup"
WEEKLY_BASE="/mnt/hdd3/immich-backup"
LOG="/home/taz/scripts/immich/immich.log"

# Restore settings
USER_OWNER="taz"
IMMICH_DIR="/home/taz/docker/immich"

# Telegram
TOKEN="your-telegram-token"
CHAT_ID="your-telegram-chatid"

# Backup Retention
DAILY_BACKUPS=14
WEEKLY_BACKUPS=4

# Service Name
SERVICE_NAME="Immich"
```

#### Immich Configuration Variables

| Variable         | Description                                   | Example                               |
| ---------------- | --------------------------------------------- | ------------------------------------- |
| `SOURCE`         | Path to main data directory to back up        | `/home/taz/docker/immich/data/`       |
| `DEST_BASE`      | Path for daily snapshot backups               | `/mnt/hdd2/immich-backup`             |
| `WEEKLY_BASE`    | Path for weekly snapshot backups              | `/mnt/hdd3/immich-backup`             |
| `LOG`            | Log file for backup/restore output            | `/home/taz/scripts/immich/immich.log` |
| `USER_OWNER`     | Owner of restored files                       | `taz`                                 |
| `IMMICH_DIR`     | Service root directory during restore         | `/home/taz/docker/immich`             |
| `TOKEN`          | Telegram bot token for notifications          | `your-telegram-token`                 |
| `CHAT_ID`        | Telegram chat ID for notifications            | `your-telegram-chatid`                |
| `DAILY_BACKUPS`  | Number of daily backups to retain             | `14`                                  |
| `WEEKLY_BACKUPS` | Number of weekly backups to retain            | `4`                                   |
| `SERVICE_NAME`   | Service name (used in notifications/messages) | `Immich`                              |

---

### Nextcloud `.env` Example

```dotenv
# Routes
SOURCE="/home/taz/docker/nextcloud/data/"
DEST_BASE="/mnt/hdd2/nextcloud-backup"
WEEKLY_BASE="/mnt/hdd3/nextcloud-backup"
LOG="/home/taz/scripts/nextcloud/nextcloud.log"

# Restore settings
USER_OWNER="taz"
NEXTCLOUD_DIR="/home/taz/docker/nextcloud"

# Telegram
TOKEN="your-telegram-token"
CHAT_ID="your-telegram-chatid"

# Backup Retention
DAILY_BACKUPS=14
WEEKLY_BACKUPS=4

# Service Name
SERVICE_NAME="Nextcloud"
```

#### Nextcloud Configuration Variables

| Variable         | Description                                   | Example                                     |
| ---------------- | --------------------------------------------- | ------------------------------------------- |
| `SOURCE`         | Path to main data directory to back up        | `/home/taz/docker/nextcloud/data/`          |
| `DEST_BASE`      | Path for daily snapshot backups               | `/mnt/hdd2/nextcloud-backup`                |
| `WEEKLY_BASE`    | Path for weekly snapshot backups              | `/mnt/hdd3/nextcloud-backup`                |
| `LOG`            | Log file for backup/restore output            | `/home/taz/scripts/nextcloud/nextcloud.log` |
| `USER_OWNER`     | Owner of restored files                       | `taz`                                       |
| `NEXTCLOUD_DIR`  | Service root directory during restore         | `/home/taz/docker/nextcloud`                |
| `TOKEN`          | Telegram bot token for notifications          | `your-telegram-token`                       |
| `CHAT_ID`        | Telegram chat ID for notifications            | `your-telegram-chatid`                      |
| `DAILY_BACKUPS`  | Number of daily backups to retain             | `14`                                        |
| `WEEKLY_BACKUPS` | Number of weekly backups to retain            | `4`                                         |
| `SERVICE_NAME`   | Service name (used in notifications/messages) | `Nextcloud`                                 |

---

## Quickstart

1. **Clone the Repository**

   ```bash
   git clone https://github.com/bytazz/docker-snapshot-manager.git
   ```

2. **Navigate to the Scripts Folder**

   ```bash
   cd docker-snapshot-manager/scripts
   ```

3. **Create/Edit the Configuration Files**

   For each service, copy or rename your config file to `.env` and edit with your settings:

   ```bash
   mv immich/example.env immich/.env
   mv nextcloud/example.env nextcloud/.env
   ```

4. **Make the Scripts Executable**

   ```bash
   chmod +x immich/immich.sh immich/restore.sh
   chmod +x nextcloud/nextcloud.sh nextcloud/restore.sh
   ```

5. **Run or Schedule Backups**

   - Run manually: see next section.
   - Or automate with cron (see below).

---

## Script Usage

To run the backup script, execute the corresponding script inside each service's directory.

**Immich:**
```bash
./immich.sh
```

**Nextcloud:**
```bash
./nextcloud.sh
```
- Runs an incremental backup with hardlinks using **rsync**.
- Backup rotation managed via `DAILY_BACKUPS` and `WEEKLY_BACKUPS` in the `.env` file.
- Optional: Telegram notifications sent if configured.

To restore a snapshot (replace `<snapshot_id>` with folder name, e.g. `2024-03-12_daily`):

```bash
./restore.sh <snapshot_id>
```
- Restores the data from the selected snapshot to the configured `SOURCE` directory.
- File ownership/permissions set via `USER_OWNER`.
- Telegram notifications sent if configured.

> 📝 **Tip:** List available snapshots by checking your backup destination folders. The `snapshot_id` matches the timestamped directory name.

---

## Scheduling with Cron

Automate backups by adding cron jobs for each service script. Example (daily at 23:00):

```cron
00 23 * * * /bin/bash /home/taz/scripts/nextcloud/nextcloud.sh
00 23 * * * /bin/bash /home/taz/scripts/immich/immich.sh
```

- Adjust times, paths, and log files as needed.
- Ensure appropriate permissions for cron user and destination directories.
- Consider logging output and errors for troubleshooting.

---

## Troubleshooting & FAQ

- **What if my backup disk is full?**  
  Oldest snapshots are rotated out based on retention settings, but ensure enough space is available for at least one cycle.
- **Why don’t I get Telegram notifications?**  
  Check that TOKEN and CHAT_ID are correct in your `.env`. Bot must have access to the chat.
- **Can I restore just one file?**  
  Restore to a temporary directory and copy out only what you need.

For more info on rsync hardlinks: [Rsync Hardlinks FAQ](https://rsync.samba.org/FAQ.html)

---

## Notes

- **Service Scripts:** Structure and arguments in `immich.sh`, `nextcloud.sh`, and `restore.sh` are identical across services; just duplicate them and their `.env` files for every Docker service.
- **Extending:** To add a new service, copy the scripts and create a `.env` file with appropriate variables.
- ⚠️ **Important:** Always test backup and restore on non-production data before relying on this for disaster recovery.
- **Safety:** Test restore operations in a safe environment before relying on them for disaster recovery.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
