#!/bin/bash -e

if [ -z "$VM_PROXY_SETTINGS" ]
then
    echo "Not setting any proxy server settings"
    exit 0
else
    echo Setting Proxy Server settings to $VM_PROXY_SETTINGS

    echo export http_proxy=$VM_PROXY_SETTINGS > /etc/profile.d/proxies.sh
    echo export https_proxy=$VM_PROXY_SETTINGS >> /etc/profile.d/proxies.sh
    echo Acquire::http::Proxy \"$VM_PROXY_SETTINGS\"\; > /etc/apt/apt.conf
fi
