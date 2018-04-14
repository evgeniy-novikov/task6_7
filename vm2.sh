#!/bin/bash

DIRSH=`dirname $0`

cd $DIRSH
source vm2.config

ip addr add $INT_IP dev $INTERNAL_IF
ip link set $INTERNAL_IF up
ip ro add default via $GW_IP dev $INTERNAL_IF

echo "nameserver $GW_IP" >> /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

VLAN_NAME=$INTERNAL_IF.$VLAN
ip link add link $INTERNAL_IF name $VLAN_NAME type vlan id $VLAN
ip addr add $APACHE_VLAN_IP dev $VLAN_NAME

# echo 1 > /proc/sys/net/ipv4/ip_forward
# iptables -t nat -A POSTROUTING -o $EXTERNAL_IF -j MASQUERADE
# echo "nameserver 8.8.4.4" >> /etc/resolv.conf

