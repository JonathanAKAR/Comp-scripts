#!/bin/bash

# === CONFIGURATION ===
BACKUP_ROOT="/var/backups/www"
TMP_DIR="/tmp/server_backup_temp"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")


# === CHANGEABLE ===
REMOTE_USER="bk_user" #CHANGE ME
BACKUP_ROOT="/home/${REMOTE_USER}"
BACKUP_HOST="" #CHANGE_ME


if [ -z $BACKUP_HOST ]; then
	echo "Please change the default IP"
	exit 1
fi
if [ $UID -ne 0 ]; then
        echo "run this script as root"
        exit 1
fi



# === FUNCTIONS ===

backup_web_server() {
    echo "Backing up Web Server from $WEB_HOST..."
    sudo tar -czf /tmp/web_config.tar.gz /etc/apache2 /var/www/html
    ssh "$REMOTE_USER@$BACKUP_HOST" "mkdir -p ${BACKUP_ROOT}"
    scp /tmp/web_config.tar.gz ${REMOTE_USER}@${BACKUP_HOST}:${BACKUP_ROOT}/web_backup_$DATE.tar.gz
    rm /tmp/web_config.tar.gz
    echo "Web server backup saved to $BACKUP_ROOT/web_backup_$DATE.tar.gz"
}


# === MAIN MENU ===
backup_web_server
