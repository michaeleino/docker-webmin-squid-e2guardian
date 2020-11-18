FROM debian:buster-slim
LABEL maintainer="Michael Fayez <michaeleino@hotmail.com>"
ARG WEBMINVER=1.962



RUN DEBIAN_FRONTEND=noninteractive && \
    rm /etc/apt/apt.conf.d/docker-gzip-indexes && \
    apt-get -o Acquire::GzipIndexes=false update && apt-get upgrade -y && \
    apt install wget gnupg -y && \
    echo "deb https://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list && \
    cd /root && \
    wget http://www.webmin.com/jcameron-key.asc && \
    apt-key add jcameron-key.asc && rm jcameron-key.asc && \
## installing Webmin Squid Nginx
    apt-get -o Acquire::GzipIndexes=false update && apt-get install webmin squid nginx libevent-core-2.1-6 libevent-pthreads-2.1-6 libtommath1 -y && \
    echo root:webmin | chpasswd

ADD ./config /config
## installing E2guardian
RUN wget https://e2guardian.numsys.eu/v5.5.dev/e2debian_buster_V5.5.1_20201116.deb && \
    dpkg -i e2debian_buster_V5.5.1_20201116.deb && \
    apt-get -f install && \
    rm e2debian_buster_V5.5.1_20201116.deb && \
    apt purge exim4-* -y && apt autoremove -y && \
    mv /config/starter.sh /usr/bin/ &&\
    sed -i '1idaemon off;' /etc/nginx/nginx.conf && \
    sed -i 's/-sYC/-sYCNd 1/g' /etc/systemd/system/multi-user.target.wants/squid.service && \
    sed -i 's/squid3/squid/g' /etc/webmin/squid/config && \
    wget https://master.dl.sourceforge.net/project/dgwebminmodule/dgwebmin-stable/0.7/dgwebmin-0.7.1.wbm && \
    /usr/share/webmin/install-module.pl dgwebmin-0.7.1.wbm && \
    sed -i 's/dansguardian/e2guardian/g' /etc/webmin/dansguardian/config && \
    sed -i 's/sbin/usr\/sbin/g' /etc/webmin/dansguardian/config && \
    ln -s /etc/e2guardian/{e2guardian,dansguardian}.conf && \
    rm dgwebmin-0.7.1.wbm

#     # mv /config/rs-nginx.conf /etc/nginx/conf.d/ && \
#     rm -r /config

VOLUME ["/var/www/html"]
# VOLUME ["/etc/squid/squid.conf"]
VOLUME ["/var/log/"]
EXPOSE 80
EXPOSE 3128
EXPOSE 10000

CMD ["/usr/bin/starter.sh"]
