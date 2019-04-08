#!/bin/bash

# cpprestsdk

# Exit if any command fails
set -e

BUILD_DIR_ROOT=$(pwd)

cd  cpprestsdk/Release
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DBOOST_INCLUDEDIR=${BUILD_DIR_ROOT}/boost -DBOOST_LIBRARYDIR=${BUILD_DIR_ROOT}/boost -DWERROR=0
make
sudo make install
cd ../../..
