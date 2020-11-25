## building squid4 with ssl
FROM debian:buster-slim as squidbuilder
## taken from https://github.com/sebastian-king/squid3-ssl && \
ADD ./config/squid-ssl.patch /config/
RUN apt-get update && \
    squid_release=$(apt-cache policy squid | grep Candidate: | awk '{print $2}') && \
    squid_version=$(echo $squid_release | awk -F- '{print $1}') && \
    codename=$(grep VERSION_CODENAME /etc/os-release | awk -F= '{print $2}') && \
    architecture=$(dpkg --print-architecture) && \
    echo "squid_release=${squid_release}" >> /config/versions && \
    echo "squid_version=${squid_version}" >> /config/versions && \
    echo "architecture=${architecture}" >> /config/versions && \
    echo "deb-src http://deb.debian.org/debian $codename main" >> /etc/apt/sources.list && \
    apt-get update && \
    cd /usr/src/ && \
    apt-get install dpkg-dev devscripts build-essential fakeroot libssl-dev squid-langpack logrotate libdbi-perl -y && \
    apt-get source squid -y && \
    apt-get build-dep squid -y
    # apt-get install devscripts build-essential fakeroot libssl-dev squid-langpack logrotate libdbi-perl -y && \
RUN . /config/versions && \
    cd "/usr/src/squid-${squid_version}" && \
    patch -p0  </config/squid-ssl.patch && \
    ./configure && \
    debuild -us -uc -b && \
    cd ../
    #&& \
    # apt-get install squid-langpack logrotate libdbi-perl -y && \
RUN . /config/versions && \
    cd /usr/src && \
    dpkg -i squid_"${squid_release}"_"${architecture}".deb squid-common_"${squid_release}"_all.deb && \
    # apt-get remove devscripts build-essential fakeroot dpkg-dev -y && \
    # apt-get autoremove -y && \
    cat /config/versions && \
    cp squid_"${squid_release}"_"${architecture}".deb squid-common_"${squid_release}"_all.deb /config/


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
    apt-get -o Acquire::GzipIndexes=false update && apt-get install supervisor webmin nginx libevent-core-2.1-6 libevent-pthreads-2.1-6 libtommath1 -y && \
    wget https://master.dl.sourceforge.net/project/dgwebminmodule/dgwebmin-stable/0.7/dgwebmin-0.7.1.wbm && \
    /usr/share/webmin/install-module.pl dgwebmin-0.7.1.wbm && \
    rm dgwebmin-0.7.1.wbm && \
## reset root password to webmin ## IMPORTANT TO CHANGE ON FIRST RUN
    echo root:webmin | chpasswd

ADD ./config /config
## installing squid4 ssl
# RUN sh /config/install-squid-with-ssl-support.sh
COPY --from=squidbuilder /config/*.deb /config/versions /config/
# RUN apt-get install libssl-dev squid-langpack logrotate libdbi-perl \
#     libecap3 libecap3-dev libcap-dev libcap2 libnetfilter-conntrack3 -y && \
RUN apt-get install -y /config/squid*.deb

## installing E2guardian
RUN wget https://e2guardian.numsys.eu/v5.5.dev/e2debian_buster_V5.5.1_20201116.deb && \
    dpkg -i e2debian_buster_V5.5.1_20201116.deb && \
    apt-get -f install && \
    rm e2debian_buster_V5.5.1_20201116.deb && \
    apt purge exim4-* wget -y && apt autoremove -y && \
    mv /config/starter.sh /usr/bin/ &&\
    rm -rf /config && \
    sed -i '1idaemon off;' /etc/nginx/nginx.conf && \
    # sed -i 's/-sYC/-sYCNd 1/g' /etc/systemd/system/multi-user.target.wants/squid.service && \
    sed -i 's/SQUID_ARGS="-YC -f $CONFIG"/SQUID_ARGS="-sYCNd 1 -f $CONFIG"/g' /etc/init.d/squid && \
    sed -i 's/squid3/squid/g' /etc/webmin/squid/config && \
    sed -i 's/dansguardian/e2guardian/g' /etc/webmin/dansguardian/config && \
    sed -i 's/sbin/usr\/sbin/g' /etc/webmin/dansguardian/config && \
    ln -s /etc/e2guardian/{e2guardian,dansguardian}.conf && \
    rm -rf /config

VOLUME ["/var/www/html"]
# VOLUME ["/etc/squid/squid.conf"]
VOLUME ["/var/log/"]
EXPOSE 80
EXPOSE 3128
EXPOSE 10000

# CMD ["/usr/bin/starter.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
