#!/bin/bash -e
#
# Building nmos-cpp code

BUILD_DIR_ROOT=$(pwd)

cd nmos-cpp/Development/
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DBOOST_INCLUDEDIR=${BUILD_DIR_ROOT}/boost -DBOOST_LIBRARYDIR=${BUILD_DIR_ROOT}/boost/lib -DWEBSOCKETPP_INCLUDE_DIR=${BUILD_DIR_ROOT}/cpprestsdk/Release/libs/websocketpp
make
cd ../../..

# now add the path
echo export "PATH=\$PATH":${BUILD_DIR_ROOT}/nmos-cpp/Development/build >> ~/.bashrc
