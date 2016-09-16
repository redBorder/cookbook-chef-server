# Cookbook Name:: Chef-server
#
# Provider:: chef
#

action :add do
  begin
    memory = new_resource.memory
    chef_active = new_resource.chef_active
    postgresql = new_resource.postgresql
    postgresql_memory = new_resource.postgresql_memory

    if !::File.directory?("/opt/opscode")

      if !node["chef-server"]["installed"]
        Chef::Log.info("Installing chef services")
        # install package
        yum_package "redborder-chef-server" do
          action :upgrade
          flush_cache [ :before ]
        end
        execute 'Configuring chef-server' do
          command '/usr/bin/chef-server-ctl reconfigure &>> /root/.install-chef-server.log'
        end
        execute 'Stopping default private-chef-server services' do 
          command ("chef-server-ctl graceful-kill")
        end
        node.default["chef-server"]["installed"] = true
      end

    end
#TODO: Chef services configuration (erchef, solr4, etc...)

    if postgresql
      # call to postgresql resource 
      chef_server_postgresql "Postgresql configuration" do
        chef_active false
        srmode "master"
        action :add
      end
    end 

     
    Chef::Log.info("Chef services has been configurated correctly.")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin
    logdir = new_resource.logdir

    Chef::Log.info("Chef services has been deleted correctly.")
  rescue => e
    Chef::Log.error(e.message)
  end
end

