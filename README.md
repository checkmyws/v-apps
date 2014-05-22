This is a repository for building virtual servers, applications and appliances with Packer, Vagrant and the likes…

## Available builds

### Ubuntu Server 14.04 Trusty 64 bits

This one is a basic Ubuntu Server 14.04 install from official ISO done with packer.

	packer build trusty64.json

Build a VirtualBox and a vagrant box ready to be consumed by

	vagrant up

This server has two networks interfaces attached :

- eth0 is a NAT only interface.
- eth1 is a hostonly interface bind on 192.168.56.10 address

### ELK

You need to build first a base trusty64 box like the one above

Kibana access at http://192.168.56.20/kibana

## Notes

More to come…