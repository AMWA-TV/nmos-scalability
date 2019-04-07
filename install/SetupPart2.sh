#!/bin/bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# define array of scripts to run
SCRIPTS_TO_RUN[0]='FetchSources.sh'
SCRIPTS_TO_RUN[1]='InstallToolsAndLibs.sh'
SCRIPTS_TO_RUN[2]='BuildCmake.sh'
SCRIPTS_TO_RUN[3]='BuildBoost.sh'
SCRIPTS_TO_RUN[4]='BuildCppRestSdk.sh'
SCRIPTS_TO_RUN[5]='BuildResponder.sh'
SCRIPTS_TO_RUN[6]='BuildNmos-cpp.sh'
SCRIPTS_TO_RUN[7]='BuildDnsmasq.sh'

# In case of error all start from particular script (zero indexed)
if [ $# -eq 0 ]
  then
    # Start from first script
    START_WITH=0
  else
    echo starting starting from $1
    START_WITH=$1
fi

# get length of an array
tLen=${#SCRIPTS_TO_RUN[@]}

# Iterate through scripts
for (( i=$START_WITH; i<${tLen}; i++ ));
do
  source ${SCRIPT_DIR}/${SCRIPTS_TO_RUN[$i]}
  if [ $? -ne 0 ]
  then
    echo script ${SCRIPTS_TO_RUN[$i]} failed
    exit 1
  else
    echo script ${SCRIPTS_TO_RUN[$i]} passed
  fi
done

read -p "Press ENTER to reboot now or CTRL-C to abort"
sudo shutdown -r now
