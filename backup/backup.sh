#!/bin/bash

# === CONFIGURATION ===
BACKUP_ROOT="/var/backups/www"
TMP_DIR="/tmp/server_backup_temp"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
mkdir -p "$BACKUP_ROOT" "$TMP_DIR"
REMOTE_USER="backup_user"

# Replace with actual IPs
WEB_HOST="" #CHANGE_ME


if [ -z $WEB_HOST || $UID -ne 0 ]; then
	echo "Please change the default IP && run this script as root"
fi

# === FUNCTIONS ===

backup_web_server() {
    echo "Backing up Web Server from $WEB_HOST..."
    ssh "$REMOTE_USER@$WEB_HOST" "sudo tar -czf /tmp/web_config.tar.gz /etc/apache2 /var/www/html"
    scp "$REMOTE_USER@$WEB_HOST:/tmp/web_config.tar.gz" "$BACKUP_ROOT/web_backup_$DATE.tar.gz"
    ssh "$REMOTE_USER@$WEB_HOST" "rm /tmp/web_config.tar.gz"
    echo "Web server backup saved to $BACKUP_ROOT/web_backup_$DATE.tar.gz"
}


# === MAIN MENU ===
backup_web_server
