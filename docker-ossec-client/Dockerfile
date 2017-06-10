FROM phusion/baseimage:0.9.18
MAINTAINER Zach Roof <zroof85@gmail.com>

# The items in this directory are heavily inspired from
# https://github.com/xetus-oss/docker-ossec-server

# I took the Dockerfile and modified it for OSSEC agent functionality

# I added in the following line for updates (including security updates)
RUN apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold"

# I added automatic security updates via
# https://help.ubuntu.com/community/AutomaticSecurityUpdates
# PROD-TODO: Set up reboot functionality for security installations that need
# this functionality
ADD 20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades
RUN apt-get install -y unattended-upgrades &&\
  chmod 750 /etc/apt/apt.conf.d/20auto-upgrades

RUN curl https://ossec.wazuh.com/repos/apt/conf/ossec-key.gpg.key -o ossec-key.gpg.key &&\
  apt-key add ossec-key.gpg.key && rm -v ossec-key.gpg.key &&\
  echo "deb http://ossec.wazuh.com/repos/apt/ubuntu trusty main" >> /etc/apt/sources.list &&\
  apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -yf install expect ossec-hids-agent \
  ossec-hids-agent=2.8.3-4trusty

COPY ossec.conf	/var/ossec/etc/
RUN chmod -R 750 /var/ossec/ &&\
  chown -R ossec:ossec /var/ossec/

COPY run.sh	/
RUN chmod -R 750 /run.sh &&\
  chown -R ossec:ossec /run.sh

VOLUME ["/var/instance_log"]

# Expose ports for sharing
EXPOSE 1514/udp 1515/tcp

ENTRYPOINT ["/run.sh"]
