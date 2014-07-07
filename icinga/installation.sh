#!/bin/bash

echo "Europe/Paris" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

apt-get update
apt-get upgrade -y

apt-get install -y nano bash-completion libapache2-mod-php5 libperl-dev libgd2-xpm-dev apache2-utils libltdl-dev php5-gd fping snmp ntp smbclient nmap saidar traceroute php5-snmp curl gettext build-essential libglib2.0-dev

groupadd -g 9000 nagios
groupadd -g 9001 nagcmd
useradd -u 9000 -g nagios -G nagcmd -d /usr/local/icinga -c "Nagios Admin" nagios

cd /root
wget https://github.com/Icinga/icinga-core/releases/download/v1.11.2/icinga-1.11.2.tar.gz
tar xzf icinga-1.11.2.tar.gz
cd icinga-1.11.2
./configure --prefix=/usr/local/icinga --enable-perfdata --enable-classicui-standalone --enable-nagiosenv --with-icinga-user=nagios --with-icinga-group=nagios --with-command-user=nagios --with-command-group=nagcmd --enable-event-broker --enable-nanosleep --enable-embedded-perl --with-perlcache
make all

make install
make install-init
make install-commandmode
make install-eventhandlers
make install-config
make install-webconf
cd ../
a2enconf icinga
a2enmod cgi

htpasswd -cb /usr/local/icinga/etc/htpasswd.users icingaadmin manager
adduser www-data nagcmd


## plugins

apt-get install -y libgnutls-dev libmysqlclient15-dev libssl-dev libsnmp-perl libkrb5-dev libldap2-dev libsnmp-dev libnet-snmp-perl gawk libwrap0-dev libmcrypt-dev fping snmp gettext smbclient dnsutils

wget https://www.monitoring-plugins.org/download/nagios-plugins-1.5.tar.gz
tar xzf nagios-plugins-1.5.tar.gz
cd nagios-plugins-1.5
./configure --with-nagios-user=nagios --with-nagios-group=nagios --enable-extra-opts --prefix=/usr/local/icinga
make 
make install
cd ../

## nrpe

tar xzf nrpe-2.15.tar.gz
cd nrpe-2.15
./configure --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/x86_64-linux-gnu --enable-ssl \
--with-log-facility --enable-command-args --enable-threads=posix --prefix=/usr/local/icinga \
--with-trusted-path=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/icinga/bin:/usr/local/icinga/libexec
make all
make install
cp init-script.debian /etc/init.d/nrpe
chmod 755 /etc/init.d/nrpe
cp sample-config/nrpe.cfg /usr/local/icinga/etc/
update-rc.d nrpe defaults
/etc/init.d/nrpe start

## pnp

apt-get install -y librrd-dev rrdtool librrds-perl

wget http://downloads.sourceforge.net/project/pnp4nagios/PNP-0.6/pnp4nagios-0.6.21.tar.gz
tar xzf pnp4nagios-0.6.21.tar.gz
cd pnp4nagios-0.6.21
./configure --with-nagios-user=nagios --with-nagios-group=nagios --with-httpd-conf=/etc/apache2/conf-available
make all
make fullinstall
a2enconf pnp4nagios
a2enmod rewrite
mv /etc/apache2/conf-available/pnp4nagios.conf /etc/apache2/conf.d/
echo "broker_module=/usr/local/pnp4nagios/lib/npcdmod.o config_file=/usr/local/pnp4nagios/etc/npcd.cfg" >> /usr/local/icinga/etc/icinga.cfg
sed -i 's/nagios\/etc\/htpasswd.users/icinga\/etc\/htpasswd.users/g' /etc/apache2/conf.d/pnp4nagios.conf
rm /usr/local/pnp4nagios/share/install.php
cd ../

## Live status

wget http://mathias-kettner.de/download/mk-livestatus-1.2.4p3.tar.gz
tar xzf mk-livestatus-1.2.4p3.tar.gz
cd mk-livestatus-1.2.4p3
./configure --prefix=/usr/local/icinga
make all
make install

echo "broker_module=/usr/local/icinga/lib/mk-livestatus/livestatus.o /usr/local/icinga/var/rw/live" >> /usr/local/icinga/etc/icinga.cfg


## Adagios

apt-get install -y python-pip libapache2-mod-wsgi git python-django python-simplejson libgmp-dev python-dev python-paramiko
pip install pynag adagios

sed -i 's|/etc/nagios/nagios.cfg|/usr/local/icinga/etc/icinga.cfg|;' adagios.conf
sed -i 's|sudo /etc/init.d/nagios|sudo /etc/init.d/icinga|;' adagios.conf
sed -i 's|nagios_url = "/nagios"|nagios_url = "/icinga"|;' adagios.conf
sed -i 's|destination_directory = "/etc/nagios/adagios/"|destination_directory = "/usr/local/icinga/etc/adagios/"|;' adagios.conf
sed -i 's|livestatus_path = None|livestatus_path = "/usr/local/icinga/var/rw/live"|;' adagios.conf
sed -i 's|nagios_binary="/usr/sbin/nagios"|nagios_binary="/usr/local/icinga/bin/icinga"|;' adagios.conf
sed -i 's|pnp_filepath="/usr/share/nagios/html/pnp4nagios/index.php"|pnp_filepath="/usr/local/pnp4nagios/share/index.php"|;' adagios.conf

mkdir /usr/local/icinga/etc/adagios
chown nagios:nagios /usr/local/icinga/etc/adagios/
pynag config --append cfg_dir=/usr/local/icinga/etc/adagios

echo "Defaults:nagios    #!requiretty" >> /etc/sudoers
echo "nagios             ALL = (root) NOPASSWD: /etc/init.d/icinga"  >> /etc/sudoers

cp /usr/local/lib/python2.7/dist-packages/adagios/apache/adagios.conf /etc/apache2/conf.d/adagios.conf
cp /usr/local/lib/python2.7/dist-packages/adagios/etc/adagios/adagios.conf /etc/adagios/
a2enconf adagios

update-rc.d icinga defaults
update-rc.d npcd defaults

service apache2 restart
service npcd restart
service icinga restart