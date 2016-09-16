# Cookbook Name:: Chef-server
#
# Provider:: chef
#

action :add do
  begin
    memory = new_resource.memory
    datadir = new_resource.datadir
    user = new_resource.user
    group = new_resource.group
    srmode = new_resource.srmode
    chef_active = new_resource.chef_active

    template "#{datadir}/postgresql.conf" do
      source "postgresql.conf.erb"
      owner user
      group group
      mode 0644
      cookbook "chef-server"
      variables(:memory => memory)
      notifies :restart, "service[postgresql]", :delayed 
#      notifies :restart, "service[pgpool]", :delayed if manager_services["pgpool"]
      notifies :reload, "service[opscode-erchef]", :delayed if chef_active
 #     notifies :restart, "service[rb-webui]", :delayed if manager_services["rb-webui"]
 #     notifies :restart, "service[rb-workers]", :delayed if manager_services["rb-workers"]
    end

   # if srmode == "master"
   #   
   # else

   # end 
    
 #  service "postgresql_start" do
 #     service_name "postgresql"
 #     supports :start => true, :enable => true
 #     action [:enable,:start]
 #   end
    service "postgresql" do
      service_name "postgresql"
      supports :status => true, :reload => true, :restart => true, :start => true, :enable => true
      action [:enable, :start]
    end
 
    Chef::Log.info("Chef services has been configurated correctly.")
  rescue => e
    Chef::Log.error(e)
  end
end

action :remove do
  begin
    logdir = new_resource.logdir

    Chef::Log.info("Chef services has been deleted correctly.")
  rescue => e
    Chef::Log.error(e)
  end
end

