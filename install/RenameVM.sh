#!/bin/bash -e
#

if [ $# -eq 1 ]
  then
    echo "Changing Hostname to: $1"
    hostname $1
    sed -i -- 's/mininet-vm/'$1'/g' /etc/hosts
    sed -i -- 's/mininet-vm/'$1'/g' /etc/hostname
#    sudo sh -c 'sed -i -- '\''s/mininet-vm/'$1'/g'\'' /etc/hosts'
#    sudo sh -c 'sed -i -- '\''s/mininet-vm/'$1'/g'\'' /etc/hostname'
fi

