#!/bin/bash

# I added some retry logic if the manager isn't initially available
while [ ! -f /var/ossec/etc/client.keys ];
do
    /var/ossec/bin/agent-auth -m manager.ossec -p 1515
    sleep 60
done

# Everything else in this script was modified from
# https://github.com/xetus-oss/docker-ossec-server/blob/master/run.bash

function ossec_shutdown(){
/var/ossec/bin/ossec-control stop;
}

# Trap exit signals and do a proper shutdown
trap "ossec_shutdown; exit" SIGINT SIGTERM

#
# Startup the services
#

# If agent-auth could establish an initial connection, give it time to
# negitotiate with the server.
# PROD-TODO Set up an event for this purpose

sleep 20
/var/ossec/bin/ossec-control start

# give ossec a reasonable amount of time to start before checking status
# PROD-TODO Set up an event for this purpose
sleep 15
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
    # before worrying.
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
