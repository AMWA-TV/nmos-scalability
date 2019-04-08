#!/bin/bash -e
#
# fetch, build and install dnsmask

wget "http://www.thekelleys.org.uk/dnsmasq/dnsmasq-2.80.tar.gz"
tar -zxvf dnsmasq-2.80.tar.gz

cd dnsmasq-2.80
sudo make install
cd ..
sudo sh -c 'nmos-scalability/bin/mn-hosts 4096 >/etc/hosts.mininet'
