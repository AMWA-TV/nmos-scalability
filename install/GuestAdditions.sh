#!/bin/bash
# no -e used as VBoxLinuxAdditions.run reports a error
# (which is actually becaiuse a reboot is needed to come up properly)

mount /dev/cdrom /media/cdrom
cd /media/cdrom

#run guest additions
./VBoxLinuxAdditions.run

# add permissions for mininet account
adduser mininet vboxsf

