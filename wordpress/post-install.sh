#!/bin/bash

sudo apt-get update; sudo apt-get -y upgrade

export DEBIAN_FRONTEND=noninteractive
echo 'mariadb-server mysql-server/root_password password vagrant' | sudo debconf-set-selections
echo 'mariadb-server mysql-server/root_password_again password vagrant' | sudo debconf-set-selections

# you can see what's has been seeded with 'sudo cat /var/cache/debconf/passwords.dat'

#sudo sh -c "sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password vagrant'"
#sudo sh -c "debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password vagrant'"

sudo apt-get install -y php5-mysqlnd nginx php5-fpm php5-gd php-pear unzip mariadb-server

mysql -uroot -pvagrant -e "CREATE DATABASE wordpress;"
#mysqladmin -u root password vagrant

wget http://fr.wordpress.org/latest-fr_FR.zip
unzip latest-fr_FR.zip
sudo rm /usr/share/nginx/html/index.html
sudo mv wordpress/* /usr/share/nginx/html/
sudo chown -R www-data:www-data /usr/share/nginx/html/*
rmdir wordpress ; rm latest-fr_FR.zip

cd /home/vagrant/files/etc
sudo cp nginx/nginx.conf /etc/nginx/
sudo cp nginx/sites-available/default /etc/nginx/sites-available/
sudo cp wordpress/wp-config.php /usr/share/nginx/html/wp-config.php

sudo sh -c "echo 'cgi.fix_pathinfo=1' >> /etc/php5/fpm/php.ini"

sudo service php5-fpm restart
sudo service nginx restart
