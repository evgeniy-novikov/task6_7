#!/bin/bash

DIRSH=`dirname $0`

cd $DIRSH
source vm1.config
HOSTNAME='vm1'

if [ "$EXT_IP" != "DHCP" ]; then

	ip addr add $EXT_IP dev $EXTERNAL_IF
	ip ro add default via $EXT_GW dev $EXTERNAL_IF
	echo "nameserver $EXT_GW" >> /etc/resolv.conf
	echo "nameserver 8.8.4.4" >> /etc/resolv.conf
#	echo "$EXT_IP"
fi
ip addr add $INT_IP dev $INTERNAL_IF
ip link set $INTERNAL_IF up

VLAN_NAME=$INTERNAL_IF.$VLAN
ip link add link $INTERNAL_IF name $VLAN_NAME type vlan id $VLAN
ip addr add $VLAN_IP dev $VLAN_NAME
ip link set $VLAN_NAME up

echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o $EXTERNAL_IF -j MASQUERADE

CUR_IP=$(ip -4 a | grep $EXTERNAL_IF | grep inet | awk '{print $2}' | sed 's/\/.*$//g')
echo $CUR_IP

################# CERT CREATE CONFIG ##########################
echo "
[ req ]
default_bits                = 4096
default_keyfile             = privkey.pem
distinguished_name          = req_distinguished_name
req_extensions              = v3_req

[ req_distinguished_name ]
countryName                 = Country Name (2 letter code)
countryName_default         = UK
stateOrProvinceName         = State or Province Name (full name)
stateOrProvinceName_default = Wales
localityName                = Locality Name (eg, city)
localityName_default        = Cardiff
organizationName            = Organization Name (eg, company)
organizationName_default    = Example UK
commonName                  = Common Name (eg, YOUR name)
commonName_default          = one.test.app.example.net
commonName_max              = 64

[ v3_req ]
basicConstraints            = CA:FALSE
keyUsage                    = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName              = @alt_names

[alt_names]
IP.1   = $CUR_IP
DNS.1   = $HOSTNAME" > /usr/lib/ssl/openssl-san.cnf 

########## SSL ######

openssl genrsa -out /etc/ssl/certs/root-ca.key 4096
openssl req -x509 -new -key /etc/ssl/certs/root-ca.key -days 365 -out /etc/ssl/certs/root-ca.crt -subj "/C=UA/L=Kharkov/O=HOME/OU=IT/CN=vm1"
openssl genrsa -out /etc/ssl/certs/web.key 4096
openssl req -new -key /etc/ssl/certs/web.key -out /etc/ssl/certs/web.csr -config /usr/lib/ssl/openssl-san.cnf -subj "/C=UA/L=Kharkov/O=DLNet/OU=NOC/CN=$HOSTNAME"
openssl x509 -req -in /etc/ssl/certs/web.csr -CA /etc/ssl/certs/root-ca.crt  -CAkey /etc/ssl/certs/root-ca.key -CAcreateserial -out /etc/ssl/certs/web.crt -days 365 -extensions v3_req -extfile /usr/lib/ssl/openssl-san.cnf

cat /etc/ssl/certs/root-ca.crt >> /etc/ssl/certs/web.crt
###############################################################

################### NGINX INSTALL##############################
apt update && apt install nginx -y
###############################################################

################### NGINX CONFIG ##############################
rm -r /etc/nginx/sites-enabled/*
cp /etc/nginx/sites-available/default  /etc/nginx/sites-available/$HOSTNAME
echo '### CONFIG ###' > /etc/nginx/sites-available/$HOSTNAME
echo "
upstream $HOSTNAME {
server $APACHE_VLAN_IP:80;
}
server {
listen  $CUR_IP:$NGINX_PORT ssl $HOSTNAME_server;
server_name $HOSTNAME
ssl on;
ssl_certificate /etc/ssl/certs/web.crt;
ssl_certificate_key /etc/ssl/certs/web.key;
 location / {
            proxy_pass http://$HOSTNAME;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
    }
} " >> /etc/nginx/sites-available/$HOSTNAME
ln -s /etc/nginx/sites-available/$HOSTNAME /etc/nginx/sites-enabled/$HOSTNAME

/etc/init.d/nginx restart

##################### APLY ##################################
echo "###### done ######" 
#############################################################


