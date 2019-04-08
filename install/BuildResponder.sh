#!/bin/bash -e
#
# Build and Install Responder

patch -d mDNSResponder/ -p1 < nmos-cpp/Development/third_party/mDNSResponder/poll-rather-than-select.patch
cd mDNSResponder/mDNSPosix
HAVE_IPV6=0 make os=linux
sudo make os=linux install
cd ../..

