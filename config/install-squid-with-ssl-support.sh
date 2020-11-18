#!/bin/bash
## taken from https://github.com/sebastian-king/squid3-ssl
squid_version=$(apt-cache policy squid | grep Candidate: | awk '{print $2}' | awk -F- '{print $1}');
codename=$(grep VERSION_CODENAME /etc/os-release | awk -F= '{print $2}')
architecture=$(dpkg --print-architecture);
echo "deb-src http://deb.debian.org/debian $codename main" >> /etc/apt/sources.list
cd /usr/src/

apt-get install dpkg-dev -y

apt-get source squid -y
apt-get build-dep squid -y
apt-get install devscripts build-essential fakeroot libssl-dev -y #dpkg-dev #for debian

cd "squid-${squid_version}"

patch -p0  </config/squid-ssl.patch  # as of squid 3.5 --with-open-ssl has become --with-openssl

./configure
debuild -us -uc -b
cd ../
apt-get install squid-langpack -y
dpkg -i squid_"${squid_version}"_"${architecture}".deb squid-common_"${squid_version}"_all.deb

#et voilà, https_port is now enabled and working in squid
