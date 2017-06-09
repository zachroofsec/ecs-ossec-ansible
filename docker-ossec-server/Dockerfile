FROM phusion/baseimage:0.9.18
MAINTAINER Zach Roof <zroof85@gmail.com>

# This DOCKERFILE was heavily inspired from
# https://github.com/xetus-oss/docker-ossec-server
# I'll denote my own work where necessary

# it's usually best practice to leverage a non-root user but it seems that this
# container needs to run with root access
# FOR-PROD - Investigate more
# https://groups.google.com/forum/#!topic/ossec-list/UI6Yng70wh0

# I added in the following line for updates (including security updates)
RUN apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold"

RUN curl https://ossec.wazuh.com/repos/apt/conf/ossec-key.gpg.key -o ossec-key.gpg.key &&\
  apt-key add ossec-key.gpg.key && rm -v ossec-key.gpg.key &&\
  echo "deb http://ossec.wazuh.com/repos/apt/ubuntu trusty main" >> /etc/apt/sources.list &&\
  apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -yf install expect ossec-hids \
  ossec-hids=2.8.3-4trusty

# I added automatic security updates via
# https://help.ubuntu.com/community/AutomaticSecurityUpdates
# PROD-TODO: Set up reboot functionality for security installations that need
# this functionality
ADD 20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades
RUN apt-get install -y unattended-upgrades &&\
  chmod 750 /etc/apt/apt.conf.d/20auto-upgrades

# I added in the agent.conf for pushing configurations to agents
ADD agent.conf /var/ossec/etc/shared/agent.conf
RUN /var/ossec/bin/verify-agent-conf

#
# Add a default agent due to this bug
# https://groups.google.com/forum/#!topic/ossec-list/qeC_h3EZCxQ
#
ADD default_agent /var/ossec/default_agent
RUN service ossec restart &&\
  /var/ossec/bin/manage_agents -f /default_agent &&\
  rm /var/ossec/default_agent &&\
  service ossec stop &&\
  echo -n "" /var/ossec/logs/ossec.log

#
# Initialize the data volume configuration
#
ADD data_dirs.env /data_dirs.env
ADD init.bash /init.bash
# Sync calls are due to https://github.com/docker/docker/issues/9547
RUN chmod 750 /init.bash &&\
  sync && /init.bash &&\
  sync && rm /init.bash

#
# Add the bootstrap script
#
ADD run.bash /run.bash
RUN chmod 750 /run.bash

# Expose ports for sharing
EXPOSE 1514/udp 1515/tcp

RUN chmod -R 750 /var/ossec/ &&\
  chown -R ossec:ossec /var/ossec/

#
# Specify the data volume
#
VOLUME ["/var/ossec/data"]

#
# Define default command.
#
ENTRYPOINT ["/run.bash"]
