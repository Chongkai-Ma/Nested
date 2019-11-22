#!/bin/bash

# This is the file that can remove the old nic configuration file and cp the new one. 

IPADDR=${1}

cd /etc/sysconfig/network-scripts/
#get the nic name
NIC=$(ip addr|grep -o "2: \<e.*\: "|awk -F: '{print $2}'|sed "s/ //g")

#remove the old nic
mv ifcfg-$NIC /root/

#set up the new nic 
sed -i "s/eno1/$NIC/g" /home/nested-autoshell/ifcfg-eno1
sed -i "s/L1guestIP/$IPADDR/g"  /home/nested-autoshell/ifcfg-switch

cp -p /home/nested-autoshell/ifcfg-eno1 /etc/sysconfig/network-scripts/ifcfg-$NIC
cp -p /home/nested-autoshell/ifcfg-switch /etc/sysconfig/network-scripts/

cp -p /home/nested-autoshell/qemu-ifup /etc/
cp -p /home/nested-autoshell/qemu-ifdown  /etc/




