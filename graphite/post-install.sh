#!/bin/bash
GRAFANA_VERSION="1.5.4"
COLLECTD_VERSION="5.4.1"

apt_install () {

	# sytem upgrade
	sudo apt-get update; sudo apt-get upgrade -y
	# install nginx. libcurl3 is needed to monitor Nginx with collectd
	sudo apt-get install -y nginx libcurl3

}

graphite_install () {

	cd ~/files/scripts/
	sudo chmod 755 graphite-install.sh
	./graphite-install.sh

}

packages_install () {

	# collectd built from fpm
	cd ~/files/packages/
	echo "decompress grafana"
	tar xzf grafana-${GRAFANA_VERSION}.tar.gz
	echo "move grafana file to nginx folder"
	sudo mv grafana-${GRAFANA_VERSION}/src /usr/share/nginx/html/grafana
	# be sure it can execute start.sh to start circus and carbon-cache at restart
	sudo chmod 755 ~/files/scripts/start.sh
	sudo dpkg -i collectd-${COLLECTD_VERSION}_amd64.deb
	sudo apt-get --yes --fix-broken install

	sudo update-rc.d collectd defaults

}

configuration_install () {
	cd ~/files/etc/
	sudo cp nginx/sites-available/default /etc/nginx/sites-available/
	sudo cp grafana/config.js /usr/share/nginx/html/grafana/
	sudo cp -r collectd/* /opt/collectd/etc/
	sudo cp rc.local /etc/rc.local

}

# ----- MAIN -----------

apt_install
packages_install
graphite_install
configuration_install