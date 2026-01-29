#!/bin/bash

#check for root
if [[ "$EUID" -ne 0 ]]; then
    echo "Script must be ran as root"
    exit 1
fi

# Prompt the user for input
read -p "Enter the domain name: " domain
read -p "Enter the IP address (of name server): " ip_address
read -p "Enter the name of the user on the DNS server: " username

# Define the paths
zones_folder="/etc/bind/zones"
forward_file="$zones_folder/forward.$domain"
reverse_file="$zones_folder/reverse.$domain"
zone_file="/etc/bind/custom_named.zones"

# Check if the zones folder exists, create it if not
if [ ! -d "$zones_folder" ]; then
    mkdir -p "$zones_folder"
fi

# Create the forward lookup file
bash -c "cat <<EOF > $forward_file
\$TTL 86400
@   IN  SOA  $domain  root (
                    $(date +%Y%m%d%H) ; Serial
                    604800         ; Refresh
                    86400         ; Retry
                    2419200       ; Expire
                    86400 )      ; Minimum TTL

; Name Server Information
@       IN  NS  $username
;ns1     IN  A   $ip_address
;www     IN  A   $ip_address
EOF"
# Create the reverse lookup file
bash -c "cat <<EOF > $reverse_file
\$TTL 86400
@   IN  SOA $domain. root.$domain. (
                    $(date +%Y%m%d%H) ; Serial
                    3600         ; Refresh
                    1800         ; Retry
                    604800       ; Expire
                    86400 )      ; Minimum TTL

; Name Server Information
@       IN  NS  $username.
;$(echo $ip_address | awk -F. '{print $4}')  IN  PTR  www.$domain.
;$(echo $ip_address | awk -F. '{print $4}')  IN  PTR  ns1.$domain.
EOF"

#check if we already created a custom_zone_file file
if [ ! -f $zone_file ]; then
    touch $zone_file
    echo -e "include \"${zone_file}\";" >> /etc/bind/named.conf
fi

#create new zones
bash -c "cat <<EOF >> $zone_file

zone \"${domain}\" IN { 
  
  type master;
  
  file \"${forward_file}\";
  
  allow-update { none; };
};
"


# Display a success message
echo "Forward lookup file created successfully at $forward_file and new zones file at $zone_file."
echo "NOW DEFINE THE FOLLOWING FOR $domain :"
echo "1. A records in $forward_file"
echo "2. PTR records in $reverse_file"
echo "2. Reverse lookup zones is required in $zone_file"
