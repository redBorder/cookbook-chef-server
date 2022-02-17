# Cookbook Name:: Rabbitmq
#
# Provider:: chef
#

action :add do
  begin
    memory = new_resource.memory
    datadir = new_resource.datadir
    user = new_resource.user
    group = new_resource.group

    template "#{datadir}/rabbitmq.conf" do
      source "rabbitmq"
      owner user
      group group
      mode 0644
      cookbook "chef-server"
      variables(:memory => memory)
      notifies :restart, "service[opscode-rabbitmq]", :delayed
      notifies :reload, "service[opscode-erchef]", :delayed
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
