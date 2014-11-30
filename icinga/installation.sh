#!/bin/bash

# ------------------- VARS -------------------- #

ICINGA=1.12.0
PLUGINS=2.1
NRPE=2.15
NSCA=1.4
PNP=0.6.24
LIVE=1.2.4p5

# ------------------- END VARS ---------------- #


echo "Europe/Paris" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

apt-get update
apt-get upgrade -y

apt-get install -y nano bash-completion libapache2-mod-php5 libperl-dev libgd2-xpm-dev apache2-utils libltdl-dev php5-gd fping snmp ntp smbclient nmap saidar traceroute php5-snmp curl gettext build-essential libglib2.0-dev

groupadd -g 9000 nagios
groupadd -g 9001 nagcmd
useradd -u 9000 -g nagios -G nagcmd -d /usr/local/icinga -c "Nagios Admin" nagios

cd /home/vagrant
mkdir src
cd src
wget https://github.com/Icinga/icinga-core/releases/download/v${ICINGA}/icinga-${ICINGA}.tar.gz
tar xzf icinga-${ICINGA}.tar.gz
cd icinga-${ICINGA}
./configure --prefix=/usr/local/icinga --enable-perfdata --enable-classicui-standalone --enable-nagiosenv --with-icinga-user=nagios --with-icinga-group=nagios --with-command-user=nagios --with-command-group=nagcmd --enable-event-broker --enable-nanosleep --enable-embedded-perl --with-perlcache
make all

make install
make install-init
make install-commandmode
make install-eventhandlers
make install-config
make install-webconf
a2enconf icinga
a2enmod cgi

htpasswd -cb /usr/local/icinga/etc/htpasswd.users icingaadmin manager
adduser www-data nagcmd

cd ../

## plugins

apt-get install -y libgnutls-dev libmysqlclient15-dev libssl-dev libsnmp-perl libkrb5-dev libldap2-dev libsnmp-dev libnet-snmp-perl gawk libwrap0-dev libmcrypt-dev fping snmp gettext smbclient dnsutils

wget https://www.monitoring-plugins.org/download/monitoring-plugins-${PLUGINS}.tar.gz
tar xzf monitoring-plugins-${PLUGINS}.tar.gz
cd monitoring-plugins-${PLUGINS}
./configure --with-nagios-user=nagios --with-nagios-group=nagios --enable-extra-opts --prefix=/usr/local/icinga
make 
make install
cd ../

## nrpe

wget http://cznic.dl.sourceforge.net/project/nagios/nrpe-2.x/nrpe-${NRPE}/nrpe-${NRPE}.tar.gz
tar xzf nrpe-${NRPE}.tar.gz
cd nrpe-${NRPE}
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
cd ../

## nsca-ng

apt-get install libconfuse-dev -y
wget https://www.nsca-ng.org/download/nsca-ng-${NSCA}.tar.gz
tar xzf nsca-ng-${NSCA}.tar.gz
cd nsca-ng-${NSCA}
./configure --enable-server --enable-client --prefix=/usr/local/icinga
make all
make install
cp /home/vagrant/files/etc/nsca-ng/nsca-ng.cfg /usr/local/icinga/etc/
cd ../

## pnp4nagios

apt-get install -y librrd-dev rrdtool librrds-perl

wget http://downloads.sourceforge.net/project/pnp4nagios/PNP-0.6/pnp4nagios-${PNP}.tar.gz
tar xzf pnp4nagios-${PNP}.tar.gz
cd pnp4nagios-${PNP}
./configure --with-nagios-user=nagios --with-nagios-group=nagios --with-httpd-conf=/etc/apache2/conf-available
make all
make fullinstall
a2enconf pnp4nagios
a2enmod rewrite
#mv /etc/apache2/conf-available/pnp4nagios.conf /etc/apache2/conf-available/
echo "broker_module=/usr/local/pnp4nagios/lib/npcdmod.o config_file=/usr/local/pnp4nagios/etc/npcd.cfg" >> /usr/local/icinga/etc/icinga.cfg
sed -i 's/nagios\/etc\/htpasswd.users/icinga\/etc\/htpasswd.users/g' /etc/apache2/conf-available/pnp4nagios.conf
cp /home/vagrant/files/etc/pnp4nagios/config_local.php /usr/local/pnp4nagios/etc/config_local.php
rm /usr/local/pnp4nagios/share/install.php
cd ../

## Live status

wget http://mathias-kettner.de/download/mk-livestatus-${LIVE}.tar.gz
tar xzf mk-livestatus-${LIVE}.tar.gz
cd mk-livestatus-${LIVE}
./configure --prefix=/usr/local/icinga
make all
make install

echo "broker_module=/usr/local/icinga/lib/mk-livestatus/livestatus.o /usr/local/icinga/var/rw/live" >> /usr/local/icinga/etc/icinga.cfg
cd ../

## Adagios

apt-get install -y python-pip libapache2-mod-wsgi git python-simplejson libgmp-dev python-dev python-paramiko
pip install django==1.5 pynag adagios

ln -s /usr/local/lib/python2.7/dist-packages/adagios/etc/adagios /etc/adagios
sudo chown nagios:nagios -R /etc/adagios/


sed -i 's|/etc/nagios/nagios.cfg|/usr/local/icinga/etc/icinga.cfg|;' /etc/adagios/adagios.conf
sed -i 's|sudo /etc/init.d/nagios|sudo /etc/init.d/icinga|;' /etc/adagios/adagios.conf
sed -i 's|nagios_url = "/nagios"|nagios_url = "/icinga"|;' /etc/adagios/adagios.conf
sed -i 's|destination_directory = "/etc/nagios/adagios/"|destination_directory = "/usr/local/icinga/etc/adagios/"|;' /etc/adagios/adagios.conf
sed -i 's|livestatus_path = None|livestatus_path = "/usr/local/icinga/var/rw/live"|;' /etc/adagios/adagios.conf
sed -i 's|nagios_binary="/usr/sbin/nagios"|nagios_binary="/usr/local/icinga/bin/icinga"|;' /etc/adagios/adagios.conf
sed -i 's|pnp_filepath="/usr/share/nagios/html/pnp4nagios/index.php"|pnp_filepath="/usr/local/pnp4nagios/share/index.php"|;' /etc/adagios/adagios.conf


mkdir /usr/local/icinga/etc/adagios
chown nagios:www-data /usr/local/icinga/etc/adagios/
pynag config --append cfg_dir=/usr/local/icinga/etc/adagios/
mkdir -p /var/lib/adagios/userdata
chown -R nagios:nagios /var/lib/adagios/userdata

echo "Defaults:nagios    !requiretty" >> /etc/sudoers
echo "nagios             ALL = (root) NOPASSWD: /etc/init.d/icinga"  >> /etc/sudoers

cp /home/vagrant/files/etc/adagios/adagios.conf /etc/apache2/conf-available/adagios.conf
a2enconf adagios

cd /usr/local/icinga/etc/
git init

## Finishing

update-rc.d icinga defaults
update-rc.d npcd defaults

service apache2 restart
service npcd restart
service nrpe restart
service icinga restart