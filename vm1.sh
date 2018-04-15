#!/bin/bash

DIRSH=`dirname $0`

cd $DIRSH
source vm1.config

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
#echo "nameserver 8.8.4.4" >> /etc/resolv.conf
