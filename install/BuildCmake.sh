#!/bin/bash -e
# Fetch cmake source and build
# (we need cmake > 3.9 - only 2.8.12.2 available from apt-get)

wget "https://cmake.org/files/v3.12/cmake-3.12.3.tar.gz"
tar -zxvf cmake-3.12.3.tar.gz
cd cmake-3.12.3

./bootstrap
make
sudo make install
cd ..