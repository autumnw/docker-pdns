########################################################################
# Docker image for PowerDNS, which includes the following components
# 1. pdns daemon : powerDNS autoritative server + HTTP APIs(Zone level) on port 8081
# 2. mysql : The backend of pwoerDNS server
# 3. pdnsrestserver : Record level APIs on port 8099


FROM autumnw/centos6.5_x86-64:pdns
MAINTAINER Autumn Wang

ADD ./conf/pdnsrestserver/server.conf /etc/pdnsrestserver/server.conf
ADD ./conf/powerdns/pdns.conf /etc/powerdns/pdns.conf

EXPOSE 80 8081 8099 53/udp 53/tcp
ENTRYPOINT /usr/bin/start_services
