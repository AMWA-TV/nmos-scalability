#!/bin/bash -e

git clone https://github.com/sony/nmos-cpp

git clone https://github.com/Microsoft/cpprestsdk
cd cpprestsdk
git submodule init
git submodule update
cd ..

# Zipped Releases

# Boost
wget "https://dl.bintray.com/boostorg/release/1.67.0/source/boost_1_67_0.tar.gz"
tar -zxvf boost_1_67_0.tar.gz && mv boost_1_67_0 boost


# mDNSResponder
wget "https://opensource.apple.com/tarballs/mDNSResponder/mDNSResponder-878.30.4.tar.gz"
tar -zxvf mDNSResponder-878.30.4.tar.gz && mv mDNSResponder-878.30.4 mDNSResponder

