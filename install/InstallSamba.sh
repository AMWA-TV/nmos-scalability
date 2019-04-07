#!/bin/bash -e
#
sudo apt-get update
sudo apt-get -y install samba
sudo smbpasswd -a mininet

# Set workgroup to 'your-workgroup'
#sudo sh -c "sed -i -- 's/workgroup = WORKGROUP/workgroup = your-workgroup/g' /etc/samba/smb.conf"

# Share out /home/mininet directory
sudo sh -c 'echo [mininet]>> /etc/samba/smb.conf'
sudo sh -c 'echo path = /home/mininet>> /etc/samba/smb.conf'
sudo sh -c 'echo browsable = yes>> /etc/samba/smb.conf'
sudo sh -c 'echo valid users = mininet>> /etc/samba/smb.conf'
sudo sh -c 'echo read only = no>> /etc/samba/smb.conf'

# Stop samba active directory and domain controller service running
sudo sh -c 'echo manual | sudo tee /etc/init/samba-ad-dc.override'
sudo service smbd restart
