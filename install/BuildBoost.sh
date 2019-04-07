#!/bin/bash -e
# Build boost

cd boost
./bootstrap.sh
sudo ./b2 '--prefix=`pwd`' --with-random --with-system --with-thread --with-filesystem --with-chrono --with-atomic --with-date_time --with-regex --stagedir=. stage
cd ..
