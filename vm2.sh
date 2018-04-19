#!/bin/bash

DIRSH=`dirname $0`

cd $DIRSH
source vm2.config

ip addr add $INT_IP dev $INTERNAL_IF
ip link set $INTERNAL_IF up
ip ro add default via $GW_IP dev $INTERNAL_IF

echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

VLAN_NAME=$INTERNAL_IF.$VLAN
ip link add link $INTERNAL_IF name $VLAN_NAME type vlan id $VLAN
ip addr add "$APACHE_VLAN_IP | sed 's/\/.*$//g'" dev $VLAN_NAME
ip link set $VLAN_NAME up

#### install apache ####
apt update && apt install apache2 -y
####

#### Apache cogigure ####
VLAN_IP=`echo $APACHE_VLAN_IP | sed 's/\/.*$//g'`
echo "Listen $VLAN_IP:80" > /etc/apache2/ports.conf
/etc/init.d/apache2 restart

################################

# rm -r /etc/apache2/sites-enabled/*
# echo 1 > /proc/sys/net/ipv4/ip_forward
# iptables -t nat -A POSTROUTING -o $EXTERNAL_IF -j MASQUERADE
# echo "nameserver 8.8.4.4" >> /etc/resolv.conf
