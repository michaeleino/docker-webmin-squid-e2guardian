FROM debian:buster-slim
LABEL maintainer="Michael Fayez <michaeleino@hotmail.com>"
ARG WEBMINVER=1.962



RUN DEBIAN_FRONTEND=noninteractive && \
    rm /etc/apt/apt.conf.d/docker-gzip-indexes && \
    rm /var/lib/apt/lists/*lz4 && \
    apt-get -o Acquire::GzipIndexes=false update && apt-get upgrade -y && \
    apt install wget gnupg && \
    echo "deb https://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list && \
    cd /root && \
    wget http://www.webmin.com/jcameron-key.asc && \
    apt-key add jcameron-key.asc && rm jcameron-key.asc && \
## installing Webmin Squid Nginx
    apt-get install webmin squid nginx libevent-core-2.1-6 libevent-pthreads-2.1-6 libtommath1 -y && \
    echo root:webmin | chpasswd

## installing E2guardian
RUN wget https://e2guardian.numsys.eu/v5.5.dev/e2debian_buster_V5.5.1_20201116.deb && \
    dpkg -i e2debian_buster_V5.5.1_20201116.deb && \
    sudo apt-get -f install

ADD ./config /config && \
     mv /config/starter.sh /usr/bin/
#     # mv /config/rs-nginx.conf /etc/nginx/conf.d/ && \
#     rm -r /config

VOLUME ["/var/www/html"]
VOLUME ["/etc/squid/squid.conf"]
VOLUME ["/var/log/"]
EXPOSE 80
EXPOSE 3128
EXPOSE 10000

CMD ["/usr/bin/starter.sh"]
