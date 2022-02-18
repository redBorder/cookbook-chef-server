# Cookbook Name:: Rabbitmq
#
# Provider:: chef
#

action :add do
  begin
    memory = new_resource.memory
    config_dir = new_resource.config_dir
    chef_active = new_resource.chef_active
    user = new_resource.user
    group = new_resource.group

    template "#{config_dir}/rabbitmq.config" do
      source "rabbitmq.config.erb"
      owner user
      group group
      mode 0644
      cookbook "chef-server"
      variables(:memory => memory)
    end

    # template "#{config_dir}/rabbitmq.conf" do
    #   source "rabbitmq.conf.erb"
    #   owner user
    #   group group
    #   mode 0644
    #   cookbook "chef-server"
    #   variables(:memory => memory)
    #   notifies :restart, "service[opscode-rabbitmq]", :delayed
    #   notifies :reload, "service[opscode-erchef]", :delayed if chef_active
    # end 

    service "opscode-rabbitmq" do
      service_name "opscode-rabbitmq"
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
    #logdir = new_resource.logdir

    Chef::Log.info("Chef services has been deleted correctly.")
  rescue => e
    Chef::Log.error(e)
  end
end
