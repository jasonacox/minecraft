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

######################################
# install minecraft
######################################
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
	  :minecraft_xms => node['minecraft_xms'],
	  :minecraft_pid => node['minecraft_pid']
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
	only_if do ! File.exist?("#{node['minecraft_mcpath']}/minecraft_server.jar") end
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
	only_if do ! File.exist?("#{node['minecraft_mcpath']}/white-list.json") end
end

# create minecraft eula file
template "#{node['minecraft_mcpath']}/eula.txt" do
        source "eula.erb"
        variables(
          :minecraft_eula => node['minecraft_eula']
	)
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
	only_if do ! File.exist?("#{node['minecraft_mcpath']}/whitelist.json") end
end

######################################
# monit 
######################################
package 'monit' do
	action :install
end

# monit config
template "/etc/monit.d/minecraft.conf" do
	source "minecraft-monit.erb"
	mode 0755
	owner "root"
	group "root"
end

# monit start and set to start on boot
service 'monit' do
	action [ :enable, :start]
end

######################################
# autopatch server using yum-updatesd
######################################
package 'yum-updatesd' do
	action :install
end

# yum-updatesd config
template "/etc/yum/yum-updatesd.conf" do
	source "yum-updatesd.conf.erb"
	mode 0755
	owner "root"
	group "root"
end

service 'yum-updatesd' do
	action [ :enable, :start]
end

######################################
# create cron
######################################
template "/etc/cron.monthly/minecraft-update" do
        source "minecraft-update.erb"
        mode 0755
        owner "root"
        group "root"
	only_if do ! File.exist?('/etc/cron.monthly/minecraft-update') end
end

# create cron
template "/etc/cron.daily/minecraft-backup" do
        source "minecraft-backup.erb"
	variables :minecraft_backuppath => node['minecraft_backuppath']
        mode 0755
        owner "root"
        group "root"
	only_if do ! File.exist?('/etc/cron.daily/minecraft-backup') end
end
