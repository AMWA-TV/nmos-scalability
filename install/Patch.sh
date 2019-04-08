#!/bin/bash -e
#

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd /etc
patch -p2 < ${THIS_SCRIPT_DIR}/etc.patch
