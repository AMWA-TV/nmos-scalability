#!/bin/bash

if [ $# -ne 3 ] ; then
  echo Error:  Expecting 3 arguments: \<bridge name\> \<interface to be bridged\> \<vSwitch\>
  echo Example:  ${0##*/}  br0 eth0 s1
  exit 1
fi

# Test if bridge already exists
ifconfig $1 > /dev/null 2>&1
if [ $? -ne 1 ] ; then
  echo ABORT: bridge interface $1 already exists
  exit 1
fi

# Check to see interface to be bridged exists
ifconfig $2 > /dev/null 2>&1
if [ $? -ne 0 ] ; then
  echo ABORT: could not find interface $2
  exit 1
fi

# Check to see if vSwitch interface exists
ifconfig $3 > /dev/null 2>&1
if [ $? -ne 0 ] ; then
  echo ABORT: could not find interface $3
  exit 1
fi

echo adding bridge $1

sudo ovs-vsctl add-br $1
sudo ifconfig $1 up
sudo ifconfig $2 0
sudo ovs-vsctl add-port $1 $2
sudo dhclient -1 -pf /run/dhclient.$1.pid -lf /var/lib/dhcp/dhclient.$1.leases $1
sudo dhclient -r -pf /run/dhclient.$2.pid -lf /var/lib/dhcp/dhclient.$2.leases $2
sudo ip tuntap add mode tap $1-patch0
sudo ifconfig $1-patch0 up
sudo ip tuntap add mode tap $3-patch0
sudo ifconfig $3-patch0 up
sudo ovs-vsctl add-port $1 $1-patch0
sudo ovs-vsctl add-port $3 $3-patch0
sudo ovs-vsctl set interface $1-patch0 type=patch options:peer=$3-patch0
sudo ovs-vsctl set interface $3-patch0 type=patch options:peer=$1-patch0
