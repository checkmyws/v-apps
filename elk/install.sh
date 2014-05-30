#!/bin/bash
ES_VERSION="1.2.0"
KIBANA_VERSION="3.1.0"
LOGSTASH_VERSION="1.4.1-1-bd507eb_all"
COLLECTD_VERSION="5.4.1"

apt_install () {

	echo "Europe/Paris" > /etc/timezone
	dpkg-reconfigure -f noninteractive tzdata

	#substitue with fr archives in apt source. Should be done in preseeding.
	cp /home/vagrant/files/etc/apt/sources.list /etc/apt/
	# sytem upgrade
	apt-get update; apt-get upgrade -y
	# install nginx. libcurl3 is needed to monitor Nginx with collectd
	apt-get install -y libcurl3 openntpd bash-completion

}

nginx_install () {

	wget http://nginx.org/keys/nginx_signing.key
	apt-key add nginx_signing.key
	rm nginx_signing.key

	echo "deb http://nginx.org/packages/mainline/ubuntu/ trusty nginx" > /etc/apt/sources.list.d/nginx.list
	echo "deb-src http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> /etc/apt/sources.list.d/nginx.list

	apt-get update
	apt-get install -y nginx

}

packages_install () {

	# collectd built from fpm
	cd /home/vagrant/files/packages
	tar xzf kibana-${KIBANA_VERSION}.tar.gz
	mv kibana-${KIBANA_VERSION} /usr/share/nginx/html/kibana
	dpkg -i elasticsearch-${ES_VERSION}.deb
	dpkg -i collectd-${COLLECTD_VERSION}_amd64.deb
	dpkg -i logstash_${LOGSTASH_VERSION}.deb
	apt-get --yes --fix-broken install
	
	# add logstash user to adm group so it can read /var/log/syslog
	adduser logstash adm
	
	update-rc.d logstash defaults
	update-rc.d elasticsearch defaults 95 10
	update-rc.d collectd defaults

}

configuration_install () {
	cd /home/vagrant/files/etc
	cp nginx/sites-available/default /etc/nginx/conf.d/default.conf
	cp -r collectd/* /opt/collectd/etc/
	cp logstash/conf.d/* /etc/logstash/conf.d/

	service collectd restart
	service elasticsearch restart
	service logstash restart
	service nginx restart

}

# ----- MAIN -----------

apt_install
nginx_install
packages_install
configuration_install