#!/bin/bash
ES_VERSION="1.2.0"
KIBANA_VERSION="3.1.0"
LOGSTASH_VERSION="1.4.1-1-bd507eb_all"
COLLECTD_VERSION="5.4.1"

apt_install () {

	#substitue with fr archives in apt source. Should be done in preseeding.
	sudo cp ~/files/etc/apt/sources.list /etc/apt/
	# sytem upgrade
	sudo apt-get update; sudo apt-get upgrade -y
	# install nginx. libcurl3 is needed to monitor Nginx with collectd
	sudo apt-get install -y nginx libcurl3

}

packages_install () {

	# collectd built from fpm
	cd ~/files/packages
	tar xzf kibana-${KIBANA_VERSION}.tar.gz
	sudo mv kibana-${KIBANA_VERSION} /usr/share/nginx/html/kibana
	sudo dpkg -i elasticsearch-${ES_VERSION}.deb
	sudo dpkg -i collectd-${COLLECTD_VERSION}_amd64.deb
	sudo dpkg -i logstash_${LOGSTASH_VERSION}.deb
	sudo apt-get --yes --fix-broken install
	
	# add logstash user to adm group so it can read /var/log/syslog
	sudo adduser logstash adm
	
	sudo update-rc.d logstash defaults
	sudo update-rc.d elasticsearch defaults 95 10
	sudo update-rc.d collectd defaults

}

configuration_install () {
	cd ~/files/etc
	sudo cp nginx/sites-available/default /etc/nginx/sites-available/
	# be sure it can execute start.sh to start circus and carbon-cache at restart
	sudo cp -r collectd/* /opt/collectd/etc/
	sudo cp logstash/conf.d/logstash.conf /etc/logstash/conf.d/

}

# ----- MAIN -----------

apt_install
packages_install
configuration_install