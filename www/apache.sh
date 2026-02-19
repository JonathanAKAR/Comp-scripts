#!/bin/bash

if [ $UID -ne 0 ]; then
	echo Run this script as root
	exit 1
fi

echo "[+] Checking for internet access"
if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
    echo "Access confirmed"
    is_online=true
else
    echo "No internet access"
    is_online=false
fi


#ufw
echo "[+] Configuring firewall"
ufw enable
ufw default deny incoming
ufw default allow outgoing
ufw allow from 0.0.0.0/0 to any port 443 proto tcp
ufw allow from 0.0.0.0/0 to any port 80 proto tcp
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
	git clone https://github.com/coreruleset/coreruleset
	rm -rf /usr/share/modsecurity-crs
	cp -R coreruleset /usr/share/modsecurity-crs
	mv /usr/share/modsecurity-crs/crs-setup.conf.example /usr/share/modsecurity-crs/crs-setup.conf
	
	cat << EOF > /etc/apache2/mods-enabled/security2.conf
<IfModule security2_module>
    SecDataDir /var/cache/modsecurity
    IncludeOptional /etc/modsecurity/*.conf
    IncludeOptional "/usr/share/modsecurity-crs/*.conf"
    IncludeOptional "/usr/share/modsecurity-crs/rules/*.conf"
</IfModule>
	EOF

	echo SecRuleEngine On >> /etc/apache2/sites-available/000-default.conf
	echo SecRule ARGS:testparam "@contains test" "id:1234,deny,status:403,msg:'Test Successful'" >> /etc/apache2/sites-available/000-default.conf


fi





#try restarting machines
echo "added test rule at /etc/apache2/sites-available/000-default.conf, remove if curl http://127.0.0.1?testparam=test results in 403"
echo "try restart your machine now"
