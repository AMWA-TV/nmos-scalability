#!/bin/bash -e

cd "$( dirname "${BASH_SOURCE[0]}" )"
sudo -E ./SetProxies.sh
sudo ./RenameVM.sh $1
sudo ./Patch.sh
set +e
sudo ./GuestAdditions.sh

read -p "Press ENTER to reboot now or CTRL-C to abort"
sudo shutdown -r now


