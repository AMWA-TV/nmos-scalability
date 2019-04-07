### Installing Ubuntu Desktop for GUI interface

Operation of Mininet is via the command line interface.
However if you prefer to use a GUI (e.g. so you don't have to use a command line editor such as `nano`), you may wish to install Ubuntu Desktop.
(Note that this will take up most of the disk space on the default Mininet VM installation, requiring more disk space to be added.)

- Launch the host and login as the *mininet* user
- Run the following commands:  
  ```bash
  sudo apt-get update
  sudo apt-get install ubuntu-desktop
  ```
- To configure Ubuntu to start the desktop automatically after login:
  - Edit */etc/default/grub* and change the following line:  
    ```
    GRUB_CMDLINE_LINUX_DEFAULT="ipv6.disable=1 text "
    ```
    to:  
    ```
    GRUB_CMDLINE_LINUX_DEFAULT="ipv6.disable=1 quiet splash "
    ```
  - After editing the file, run the following command:  
    ```bash
    sudo update-grub
    ```

The next time you boot the VM, you should see the GUI login screen.

### Create another virtual disk for the VM

It can be a good idea to do this, otherwise there is a risk of running out of space on the primary disk.

In VirtualBox add a new hard disk on the *Storage* tab of the settings dialog for the VM.
The default options for a new virtual hard disk, to create a VDI (VirtualBox Disk Image) that is dynamically allocated, 10 GB in size, are OK, depending on what else you want to use it for.

Run up the VM and partition, format and mount the new disk. Add it to */etc/fstab* so this survives a reboot.

More detailed instructions can be found here: https://muffinresearch.co.uk/adding-more-disk-space-to-a-linux-virtual-machine/

### How to connect a USB drive to the VM

E.g. in order to copy files on to the VM

- First add a USB 1.1 device to the VM in VirtualBox settings
- Plug the USB device into a USB2 (*not* USB3) socket on the host machine and start the VM

Then on the VM run the following two commands (assuming the USB device has appeared as */dev/sdb1*):

```bash
sudo mkdir /media/usbstick
sudo mount -t vfat /dev/sdb1 /media/usbstick
```

More info: https://askubuntu.com/questions/285539/detect-and-mount-devices

### Using Samba to share out the *mininet* home directory to Windows

Run the script:
```bash
nmos-scalability/install/InstallSamba.sh
```

This script will install Samba and configure it to share out the `/home/mininet` directory.
Note: To configure a workgroup name other than 'WORKGROUP', see the comments in the script.

When prompted, add a password for use by Samba to authorise access:
```
New SMB password:
Retype new SMB password:
```

From Windows you should now be able to access the `/home/mininet` directory from Windows using the Samba password created above, e.g.:
```
\\10.0.254.2\mininet
```
