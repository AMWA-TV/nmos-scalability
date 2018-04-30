# NMOS Scalability

This repository establishes a test environment for [NMOS](https://github.com/AMWA-TV/nmos) Scalability using the [Mininet](https://github.com/mininet/mininet/) network rapid prototyping tool.
Mininet emulates a complete network of hosts, links, and switches on a single machine.
We extend Mininet with functions to build large-scale networks of NMOS Registries and Nodes.

The following instructions describe how to prepare the basic environment.

The contents of this repository is [licensed](LICENSE) under the terms of the Apache License 2.0.

## Set Up The Mininet Virtual Machine

### Download the 64-bit Mininet VM image

Grab it from this link: https://github.com/mininet/mininet/releases/download/2.2.2/mininet-2.2.2-170321-ubuntu-14.04.4-server-amd64.zip

### Import the VM into VirtualBox

See http://mininet.org/vm-setup-notes/.
(We're using Oracle VM VirtualBox Manager 5.1 or 5.2.)

### Increase the amount of memory and CPUs used by the VM

More memory and more CPUs is better.
On our primary test machine to simulate networks with several thousand nodes, we used 40 GBytes of memory and 12 CPUs, but it's certainly possible to run some tests with fewer.
(Note that adding a second virtual network adaptor can cause problems e.g. when trying to install additional software within the VM via the host network.)

## Install Ubuntu Desktop

While this isn't required, it certainly makes using the virtual machine more comfortable!

- Launch the host and login as "mininet"
- If you are using a network proxy, set the ``http_proxy`` environment variable appropriately
- Run the following commands:
  ```bash
  sudo -E apt-get update
  sudo -E apt-get install ubuntu-desktop
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

### Install Guest Additions to enable Shared Folders (and other Good Stuff*)
(*such as being able to resize the VM screen/desktop)

- Add an empty Optical Drive in *Settings > Storage*
- Launch the host
- Choose *Devices > Insert Guest Additions CD image...*

(The VBoxGuestAdditions.iso is installed as part of VirtualBox.)

Log in and run the following commands:

```bash
sudo mount /dev/cdrom /media/cdrom
sudo su
cd /media/cdrom
./VBoxLinuxAdditions.run
```

When the installation has finished restart the VM: ``shutdown -r now``

More detailed instructions can be found here: https://www.techrepublic.com/article/how-to-install-virtualbox-guest-additions-on-a-gui-less-ubuntu-server-host/

- Add the *mininet* user to the shared folders group: ``sudo adduser mininet vboxsf``

### Increase the number of processes and open files that a user is allowed

To do this, edit the */etc/security/limits.conf* file and add the following lines:

```
*       -    nofile       100000
*       -    nproc        500000
```

This increases the hard and soft limits, for all users, for the number of open files and the number of running threads across all processes.

### Create another virtual disk for the VM

It can be a good idea to do this, otherwise there is a risk of running out of space on the primary disk.

In VirtualBox add a new hard disk on the *Storage* tab of the settings dialog for the VM.
The default options for a new virtual hard disk, to create a VDI (VirtualBox Disk Image) that is dynamically allocated, 10 GB in size, are OK depending on what else you want to use it for.

Run up the VM and partition, format and mount the new disk. Add it to */etc/fstab* so this survives a reboot.

More detailed instructions can be found here: https://muffinresearch.co.uk/adding-more-disk-space-to-a-linux-virtual-machine/

### Mount a shared folder

This is the simplest way to copy stuff between the host and the VM.

In VirtualBox Manager, set up a permanent, auto-mount, shared folder to the local *nmos-scalability* repository directory.

This will appear as */media/sf_\<share-name\>*, and belong to the *vboxsf* group, to which we already added the *mininet* user.

On a Windows host, in order to be able to create symlinks in the shared folder, run the following:

```winbatch
cd C:/Program Files/Oracle/VirtualBox
VBoxManage setextradata <virtual-machine-name> VBoxInternal2/SharedFoldersEnableSymlinksCreate/<share-name> 1
```

Restart VirtualBox Manager.

In order to avoid limitations of the VirtualBox shared folder filesystem, it's a good idea to copy the contents of this repository onto the new virtual disk, created above.

Let's call that copy in the filesystem *\<nmos-scalability\>*.

### Prepare DNS entries for the hosts in the Mininet virtual network

Add a static lookup table for Mininet hostnames to */etc/hosts*.

```bash
cd <nmos-scalability>
sudo su
bin/mn-hosts 4096 >>/etc/hosts
```

If you prefer, you can use e.g. *dnsmasq* as described below.

### Run Mininet

Restart the VM to ensure all the settings have taken effect: ``sudo shutdown -r now``

Run the command ``sudo mn`` to experiment with the basic Mininet tool.
With no additional options, this constructs a small network and starts the built-in Mininet CLI:

```bash
*** Creating network
*** Adding controller
*** Adding hosts:
h1 h2 
*** Adding switches:
s1
*** Adding links:
(h1, s1) (h2, s1)
*** Starting controller
c0
*** Starting 1 switches
s1 ...
*** Starting CLI:
mininet>
```

Type ``h1 ping -c1 h2`` to confirm that Mininet is basically functional. Try ``h1 ping -c1 "h2"`` to confirm that DNS is working within the virtual network.

Type ``help`` for a list of the built-in commands.
Type ``exit`` to quit.

There is a step-by-step Mininet Walkthrough at: http://mininet.org/walkthrough/

## Set Up External Dependencies

### Add the multicast DNS daemon

NMOS uses the DNS Service Discovery protocol to discover Nodes and Registries on the network.
DNS-SD on Linux can be provided by either of two open-source implementations, *avahi-daemon* or *mdnsd*.
Applications may need either of these.

To build *mdnsd*, grab the source tarball from this link: https://opensource.apple.com/tarballs/mDNSResponder/mDNSResponder-878.30.4.tar.gz

Copy this onto the VM, unpack it and run:

```bash
cd <mDNSResponder>/mDNSPosix
sudo make os=linux install
```

### Add NMOS Registry and Node implementations

The test environment we're building is intended to support different NMOS Registry and Node implementations.

It has been proven with the open-source [nmos-cpp](https://github.com/sony/nmos-cpp) implementation.
Copy that repo onto the new virtual disk, and build the nmos-cpp-registry and nmos-cpp-node executables.
Install these so that they can be found on the *PATH*, and their library dependencies can be found by *LD_LIBRARY_PATH*.

## Run NMOS Mininet

We're now ready to run Mininet with our NMOS extensions.

```bash
cd <nmos-scalability>
sudo bin/nmos-mn
```

A simple network will be created, almost as before.

At the ``mininet>`` prompt, type ``help`` for a list of the built-in commands, including the NMOS extensions.

Type ``mdnsd h1 h4`` to run *mdnsd* for all hosts (*h1* to *h4*).

Type ``start_registry h1`` to start up a registry on host *h1*.

Type ``start_node h2 h4`` to start up nodes on hosts *h2*, *h3* and *h4*.

Type ``query_nodes h1`` to print a list of the registered nodes.

Type ``exit`` to quit.

## Create a larger network

The extended Mininet CLI, *nmos-mn* supports all of the same command-line options. For example, this command-line creates a network of 256 hosts without a controller:

```bash
sudo bin/nmos-mn --topo=tree,2,16 --controller=none
```

Then at the ``mininet>`` prompt, set the switches into standalone mode, start up the mDNS daemon, a registry and lots of nodes:

```
ovs_standalone
mdnsd h1 h256
start_registry h1
start_node h2 h256
```

## Additional Configuration

Other steps that might be useful...

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

### How to provide DNS for the Mininet virtual network

Rather than modifying the system */etc/hosts* file, it is possible to use *dnsmasq*.

Install from: http://www.thekelleys.org.uk/dnsmasq/doc.html

Add a "dns-nameservers 10.0.0.1" line to the loopback interface in */etc/network/interfaces*

For example:

```
# The loopback network interface
auto lo
iface lo inet loopback
    dns-nameservers 10.0.0.1
```

Then run this command: ``sudo ifup --force lo``

To create an additional hosts file and start up *dnsmasq*, run:

```bash
cd <nmos-scalability>
bin/mn-hosts 4096 >hosts.mininet
chmod +w hosts.mininet
sudo dnsmasq -h -H hosts.mininet
```
