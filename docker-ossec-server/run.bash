#!/bin/bash

# This script was heavily inspired from
# https://github.com/xetus-oss/docker-ossec-server/blob/master/run.bash
# I cleaned up the script and took out items/services not needed for the deployment

source /data_dirs.env
FIRST_TIME_INSTALLATION=false
DATA_PATH=/var/ossec/data

for ossecdir in "${DATA_DIRS[@]}"; do
  if [ ! -e "${DATA_PATH}/${ossecdir}" ]
  then
    echo "Installing ${ossecdir}"
    cp -pr /var/ossec/${ossecdir}-template ${DATA_PATH}/${ossecdir}
    FIRST_TIME_INSTALLATION=true
  fi
done

#
# Check for the process_list file. If this file is missing, it doesn't
# count as a first time installation
#
touch ${DATA_PATH}/process_list
chgrp ossec ${DATA_PATH}/process_list
chmod g+rw ${DATA_PATH}/process_list

#
# If this is a first time installation, then do the
# special configuration steps.
#
AUTO_ENROLLMENT_ENABLED=${AUTO_ENROLLMENT_ENABLED:-true}

if [ $FIRST_TIME_INSTALLATION == true ]
then

  #
  # Support auto-enrollment if configured
  #
  if [ $AUTO_ENROLLMENT_ENABLED == true ]
  then
    if [ ! -e ${DATA_PATH}/etc/sslmanager.key ]
    then
      echo "Creating ossec-authd key and cert"
      openssl genrsa -out ${DATA_PATH}/etc/sslmanager.key 4096
      openssl req -new -x509 -key ${DATA_PATH}/etc/sslmanager.key\
        -out ${DATA_PATH}/etc/sslmanager.cert -days 3650\
        -subj /CN=${HOSTNAME}/
    fi
  fi

  echo "d-i  ossec-hids/email_notification  boolean no" >> /tmp/debconf.selections

  if [ -e /tmp/debconf.selections ]
  then
    debconf-set-selections /tmp/debconf.selections
    dpkg-reconfigure -f noninteractive ossec-hids
    rm /tmp/debconf.selections
    /var/ossec/bin/ossec-control stop
  fi
fi

function ossec_shutdown(){
  /var/ossec/bin/ossec-control stop;
  if [ $AUTO_ENROLLMENT_ENABLED == true ]
  then
     kill $AUTHD_PID
  fi
}

# Trap exit signals and do a proper shutdown
trap "ossec_shutdown; exit" SIGINT SIGTERM

#
# Startup the services
#
chmod -R g+rw ${DATA_PATH}/logs/ ${DATA_PATH}/stats/ ${DATA_PATH}/queue/ ${DATA_PATH}/etc/client.keys
chown -R ossec:ossec /var/ossec/
/var/ossec/bin/ossec-control start
if [ $AUTO_ENROLLMENT_ENABLED == true ]
then
  echo "Starting ossec-authd..."
  /var/ossec/bin/ossec-authd -p 1515 -g ossec $AUTHD_OPTIONS >/dev/null 2>&1 &
  AUTHD_PID=$!
fi
sleep 15 # give ossec a reasonable amount of time to start before checking status
LAST_OK_DATE=`date +%s`

#
# Watch the service in a while loop, exit if the service exits
#
# Note that ossec-execd is never expected to run here.
#
STATUS_CMD="service ossec status | sed '/ossec-maild/d' | sed '/ossec-execd/d' | grep ' not running' | test -z"

while true
do
  eval $STATUS_CMD > /dev/null
  if (( $? != 0 ))
  then
    CUR_TIME=`date +%s`
    # Allow ossec to not run return an ok status for up to 15 seconds
    # before worring.
    if (( (CUR_TIME - LAST_OK_DATE) > 15 ))
    then
      echo "ossec not properly running! exiting..."
      ossec_shutdown
      exit 1
    fi
  else
    LAST_OK_DATE=`date +%s`
  fi
  sleep 1
done
