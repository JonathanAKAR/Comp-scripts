#!/bin/bash

if [ $UID -ne 0 ]; then
	echo Run this script as root
	exit 1
fi

read -p "Hit enter if you have already changed the appropriate config, if not exit: " TMP

#THINGS I MIGHT NEED TO SPEC
WEBROOT="/var/www/html"
WEBSITE_DOMAIN="test.com"
ACME_URL="https://ca.ncaecybergames.org/acme/acme/directory"

echo "[+] Checking for internet access"
if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
    echo "Access confirmed"
    is_online=true
else
    echo "No internet access"
    is_online=false
fi

#sanity
apt install apache2 -y && apt upgrade apache2 -y
chown -R root:www-data /var/www/html
chmod -R 755 /var/www/html


#ufw
echo "[+] Configuring firewall"
ufw enable
ufw default deny incoming
ufw default allow outgoing
ufw allow from 0.0.0.0/0 to any port 443 proto tcp
ufw allow from 0.0.0.0/0 to any port 80 proto tcp
ufw allow from 0.0.0.0/0 to any port 22 proto tcp
sed -i '/IPV6=yes/s/.*/IPV6=no/' /etc/default/ufw

#mod_security for traffic blocking
if $is_online; then
	echo "[+] Configuring modsecurity"

	#initial install
	apt install -y libapache2-mod-security2
	cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
	sed -i '/SecRuleEngine DetectionOnly/s/.*/SecRuleEngine On/' /etc/modsecurity/modsecurity.conf
	a2enmod headers && a2enmod security2
	systemctl restart apache2


	#adding rules

	#uncomment me if stuff isnt working
	#git clone https://github.com/coreruleset/coreruleset

	rm -rf /usr/share/modsecurity-crs
	cp -R coreruleset /usr/share/modsecurity-crs
	mv /usr/share/modsecurity-crs/crs-setup.conf.example /usr/share/modsecurity-crs/crs-setup.conf

	#config file stuff
	cp config_files/security2.conf /etc/apache2/mods-enabled/security2.conf

	########################################################
	####################CHANGE THIS LINE####################
	echo SecRuleEngine On >> /etc/apache2/sites-available/000-default.conf
fi

#paste in config
cp config_files/apache-000-default.conf /etc/apache2/sites-available/000-default.conf
sed -i "s|^[[:space:]]*ServerName REPLACE_ME_WITH_DOMAIN|    ServerName ${WEBSITE_DOMAIN}|" /etc/apache2/sites-available/000-default.conf
a2enmod proxy
a2enmod proxy_http

#certbot stuff
if $is_online; then

	if ! which certbot; then
		apt-get update -y
		apt-get install software-properties-common -y
		add-apt-repository universe -y
		add-apt-repository ppa:certbot/certbot -y
		apt-get update -y
		apt-get install -y certbot python3-certbot-apache
	fi

	#uncomment me later
	certbot --apache --server $ACME_URL --no-random-sleep-on-renew

	#test line
	#certbot --apache --server https://192.168.88.222/acme/acme/directory --no-random-sleep-on-renew
fi



#try restarting machines
systemctl restart apache2
echo "test if modsecurity works, curl http://127.0.0.1?q=<script>alert(1);</script> results in 403"
echo "test if modevasive works, perl /usr/share/doc/libapache2-mod-evasive/examples/test.pl"
echo "try restart your machine now"
