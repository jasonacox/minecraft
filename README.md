Description
===========

This is a Minecraft server cookbook.  It installs the dependencies and minecraft code and configuration to run minecraft server on a cloud server instances.  It has been tested on:

- AWS
- Google
- Rackspace

Requirements
============

This cookbook requires the following cookbooks:

- java
- yum 
- yum-epel 
- runit 
- chef_handler 
- windows 
- build-essential 
- dmg 
- git 
- screen 

Attributes
==========

	default['minecraft_service'] = "minecraft_server.jar"
	default['minecraft_username'] = "minecraft"
	default['minecraft_userpath'] = "/home/minecraft"
	default['minecraft_world'] = "world"
	default['minecraft_mcpath'] = "/home/minecraft/minecraft"
	default['minecraft_backuppath'] = "/home/minecraft/minecraft.backup"
	default['minecraft_cpu'] = "1"
	default['minecraft_xms'] = "512M"
	default['minecraft_server_motd'] = "Welcome to Chef Minecraft"
	default['minecraft_server_whitelist'] = "true"

Minecraft users should be added to this file...
	/templates/default/white-list.erb

INSTRUCTIONS
============

Bootstrap your new server image or use a script like this:

	#!/bin/bash
	#
	# USAGE: setup.sh <host>
	#
	# DESCRIPTION: setup server node for minecraft 
	#
	# CONFIGURE:
	KEY=/Users/youruser/.ssh/google_compute_engine
	CHEFKEY=~/chef-repo/youruser-validator.pem
	USER=youruser
	UPATH=/home/youruser
	#
	echo Setting up $1 as a chef-client - with user $USER key $KEY path $UPATH.
	#
	# copy files
	scp -i $KEY ~/chef-repo/knife.rb $USER@$1:$UPATH
	scp -i $KEY ~/chef-repo/youruser-validator.pem $USER@$1:$UPATH
	scp -i $KEY ~/minecraft/setup-chef-client.sh $USER@$1:$UPATH
	#
	# update settings
	ssh -i $KEY $USER@$1 "chmod +x setup-chef-client.sh"
	echo Run setup-chef-client.sh
	#
	# login
	ssh -i $KEY $USER@$1


FILE
----

The setup-chef-client.sh file would look something like this:

	#!/bin/bash
	cd ~
	sudo yum update
	sudo true && curl -L https://www.opscode.com/chef/install.sh | sudo bash
	sudo yum install -y git
	cd ~
	git clone git://github.com/opscode/chef-repo.git
	cd chef-repo/
	cp  ~/knife.rb ~/chef-repo
	cp  ~/youruser-validator.pem ~/chef-repo
	knife configure client ./client-config
	knife client list
	sudo mkdir /etc/chef
	sudo cp -r ~/chef-repo/client-config/* /etc/chef
	sudo chef-client


CHEF
----

Next, add the minecraft cookbook to your new server node and run...

	sudo chef-client


