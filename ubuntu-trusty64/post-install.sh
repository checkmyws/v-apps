#!/bin/bash

# stolen from https://github.com/jedi4ever/veewee/blob/master/templates/ubuntu-14.04-server-amd64/

mkdir /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
cd /home/vagrant/.ssh
wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh


# don't ask password for vagrant user
sudo groupadd -r admin
sudo usermod -a -G admin vagrant
sudo cp /etc/sudoers /etc/sudoers.orig
sudo sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=admin' /etc/sudoers
sudo sed -i -e 's/%admin ALL=(ALL) ALL/%admin ALL=NOPASSWD:ALL/g' /etc/sudoers

sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y curl nano bash-completion

# Virtual additions

## Without libdbus virtualbox would not start automatically after compile
sudo apt-get -y install --no-install-recommends libdbus-1-3

## Remove existing VirtualBox guest additions
sudo /etc/init.d/virtualbox-ose-guest-utils stop
sudo rmmod vboxguest
sudo aptitude -y purge virtualbox-ose-guest-x11 virtualbox-ose-guest-dkms virtualbox-ose-guest-utils
sudo aptitude -y install dkms

## Install the VirtualBox guest additions
VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
VBOX_ISO=VBoxGuestAdditions_$VBOX_VERSION.iso
sudo mount -o loop $VBOX_ISO /mnt
sudo yes|sh /mnt/VBoxLinuxAdditions.run
sudo umount /mnt

# Temporary fix for VirtualBox Additions version 4.3.10
# issue #12879, see https://www.virtualbox.org/ticket/12879
[ -e /usr/lib/VBoxGuestAdditions ] || ln -s /opt/VBoxGuestAdditions-$VBOX_VERSION/lib/VBoxGuestAdditions /usr/lib/VBoxGuestAdditions

# Cleanup
rm $VBOX_ISO

sudo apt-get -y autoremove

#dd if=/dev/zero of=/EMPTY bs=1M
#rm -f /EMPTY

echo "cleaning up dhcp leases"
sudo rm /var/lib/dhcp/*

echo "cleaning up udev rules"
sudo rm -f /etc/udev/rules.d/70-persistent-net.rules
sudo mkdir /etc/udev/rules.d/70-persistent-net.rules
sudo rm -rf /dev/.udev/
sudo rm /lib/udev/rules.d/75-persistent-net-generator.rules
sudo sh -c "echo 'pre-up sleep 2' >> /etc/network/interfaces"


exit

