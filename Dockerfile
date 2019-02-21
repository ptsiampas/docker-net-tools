FROM alpine:3.5
LABEL maintainer="peter@wiredelf.com"


RUN apk --update add --no-cache mtr wget curl bash htop tcpdump nmap iperf openssh-client jq nmap-ncat bind-tools

RUN rm -rf /var/cache/apk/*

ADD start.sh /start.sh
RUN chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
