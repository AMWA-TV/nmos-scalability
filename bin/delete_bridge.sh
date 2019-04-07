#!/bin/bash

if [ $# -ne 3 ] ; then
  echo Error:  Expecting 3 arguments: \<bridge name\> \<interface to be bridged\> \<vSwitch\>
  echo Example Usage: ${0##*/}  br0 eth0 s1
  exit 1
fi

# Check bridge already exists
ifconfig $1 > /dev/null 2>&1
if [ $? -ne 0 ] ; then
  echo bridge $1 to be removed does not exists
else
  echo deleting bridge $1
  sudo ifconfig $1 down
  sudo ovs-vsctl del-br $1
fi
sudo dhclient -r -pf /run/dhclient.$1.pid -lf /var/lib/dhcp/dhclient.$1.leases $1


ifconfig $1-patch0 > /dev/null 2>&1
if [ $? -ne 0 ] ; then
  echo interface $1-patch0 to be removed does not exists
else
  sudo ifconfig $1-patch0 down
  sudo ip tuntap del mode tap $1-patch0
fi

ifconfig $3-patch0 > /dev/null 2>&1
if [ $? -ne 0 ] ; then
  echo $3-patch0 to be removed does not exists
else
  sudo ifconfig $3-patch0 down
  sudo ovs-vsctl del-port $3-patch0
  sudo ip tuntap del mode tap $3-patch0
fi

# Check to see interface to be restored exists
ifconfig $2 > /dev/null 2>&1
if [ $? -ne 0 ] ; then
  echo could not find interface $2
else
  # Renue lease on interface $2
  sudo dhclient -r -pf /run/dhclient.$2.pid -lf /var/lib/dhcp/dhclient.$2.leases $2
  sudo dhclient -1 -pf /run/dhclient.$2.pid -lf /var/lib/dhcp/dhclient.$2.leases $2
fi


