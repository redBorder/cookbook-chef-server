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
      source "pgsql_postgresql.conf.erb"
      owner user
      group group
      mode 0644
      retries 2
      variables(:memory => memory_services["postgresql"])
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

