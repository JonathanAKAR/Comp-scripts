#!/bin/bash

##################################
###CHANGE THESE BEFORE STARTING###
##################################

#Hosts
WEB_IP=""
DNS_IP=""
FTP_IP=""
POSTGRES_IP=""
ROUTER_IP=""

#User Info
USER="backup" #create this when comp starts on each machine, add this to general harden script
BACKUP_DIR="/backups"
TMP_DIR="/tmp"

##################################


#Functions
backup_web_server() {
	ssh ${USER}@${WEB_IP} -t "sudo tar -cvf ${TMP_DIR}/web_config.tar.gz /etc/apache2 /var/www/html"
	scp ${USER}@${DNS_IP}:/tmp/web_config.tar.gz ${BACKUP_DIR}/web/web_config.tar.gz

}
