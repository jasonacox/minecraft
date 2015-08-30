#
# Cookbook Name:: minecraft
# Recipe:: default
# Description:: Set up a minecraft server on an EC2 server.
# Copyright 2015, Jason Cox
#
# All rights reserved - Do Not Redistribute
#

# minecraft requires java
include_recipe "java"

# minecraft admin requires screen
include_recipe "screen"

# install js engine for jsawk
cookbook_file "/usr/bin/js" do
	source "js"
	mode 0755
	owner "root"
	group "root"
end
cookbook_file "/usr/bin/jsawk" do
	source "jsawk"
	mode 0755
	owner "root"
	group "root"
end

# create startup template
template "/etc/init.d/minecraft" do
	source "minecraft.init.d.erb"
	variables( 
	  :minecraft_service => node['minecraft_service'],
	  :minecraft_username => node['minecraft_username'],
	  :minecraft_world => node['minecraft_world'],
	  :minecraft_mcpath => node['minecraft_mcpath'],
	  :minecraft_backuppath => node['minecraft_backuppath'],
	  :minecraft_cpu => node['minecraft_cpu'],
	  :minecraft_xms => node['minecraft_xms']
	)
	mode 0755
	owner "root"
	group "root"
	action :create
end

# create minecraft user
user node['minecraft_username'] do
	comment "Minecraft Server"
	home node['minecraft_userpath']
	shell "/bin/bash"
end

# create mcpath
directory node['minecraft_mcpath'] do
	mode 0755
	user node['minecraft_username']
	group node['minecraft_username']
end

directory node['minecraft_backuppath'] do
	mode 0755
	user node['minecraft_username']
	group node['minecraft_username']
end

bash "run_update" do
	user "root"
	cwd node['minecraft_userpath']
	code <<-EOH
	/etc/init.d/minecraft update
	EOH
end

# create minecraft server properties 
template "#{node['minecraft_mcpath']}/server.properties" do
        source "server.properties.erb"
        variables(
          :minecraft_world => node['minecraft_world'],
          :minecraft_server_motd => node['minecraft_server_motd'],
          :minecraft_server_whitelist => node['minecraft_server_whitelist']
        )
        mode 0664
        owner "minecraft"
        group "minecraft"
end

# create minecraft whitelist 
template "#{node['minecraft_mcpath']}/white-list.txt" do
        source "white-list.erb"
        mode 0664
        owner "minecraft"
        group "minecraft"
end

# create minecraft eula file
template "#{node['minecraft_mcpath']}/eula.txt" do
        source "eula.erb"
        variables(
          :minecraft_eula => node['minecraft_eula']
	}
        mode 0664
        owner "minecraft"
        group "minecraft"
end

bash "start_minecraft" do
        user "root"
        cwd node['minecraft_userpath']
        code <<-EOH
	sleep 20
        /etc/init.d/minecraft stop
	sleep 10
        /etc/init.d/minecraft start
	sleep 10
        /etc/init.d/minecraft status
        EOH
end

# create cron
template "/etc/cron.monthly/minecraft-update" do
        source "minecraft-update.erb"
        mode 0755
        owner "root"
        group "root"
end

# create cron
template "/etc/cron.daily/minecraft-backup" do
        source "minecraft-backup.erb"
	variables :minecraft_backuppath => node['minecraft_backuppath']
        mode 0755
        owner "root"
        group "root"
end
