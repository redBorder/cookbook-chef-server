# Cookbook Name:: Chef-server
#
# Provider:: chef
#

action :add do
  begin
    memory = new_resource.memory

    if !File.directory?("/opt/opscode")

      Chef::Log.info("Installing chef services")
      # install package
      yum_package "redborder-chef-server" do
        action :upgrade
        flush_cache [ :before ]
      end
      output = system("/usr/bin/chef-server-ctl reconfigure &>> /root/.install-chef-server.log")
      raise if !output
      system("chef-server-ctl stop") 

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

