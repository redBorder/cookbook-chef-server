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
    postgresql_vip = new_resource.postgresql_vip
    netsync = new_resource.netsync
    chef_config_path = new_resource.chef_config_path

    if !::File.directory?("/opt/opscode") and !node["chef-server"]["installed"] #Only executed if it's a custom node with chef-server

      Chef::Log.info("Installing chef services")
      # install chef-server package
      yum_package "redborder-chef-server" do
        action :upgrade
        flush_cache [ :before ]
      end

      execute 'Set 4443 as chef default port' do
        command 'echo "nginx[\'ssl_port\'] = 4443" >> /etc/opscode/chef-server.rb'
      end

      # chef-server reconfigure
      execute 'Configuring chef-server' do
        command '/usr/bin/chef-server-ctl reconfigure &>> /root/.install-chef-server.log'
      end

      # stop chef-server services
      execute 'Stopping default private-chef-server services' do
        command ("chef-server-ctl graceful-kill")
      end

      # Chef-server installation finished
      node.default["chef-server"]["installed"] = true

      #Chef server datastore configuration
      if !node["chef-server"]["datastore_configured"]
        # Load Database configuration
        db_opscode_chef = Chef::DataBagItem.load("passwords", "db_opscode_chef") rescue db_opscode_chef = {}

        if !db_opscode_chef.empty?
          Chef::Log.info("Configuring Chef-server database")
          db_host = db_opscode_chef["hostname"]
          db_port = db_opscode_chef["port"]
          db_name = db_opscode_chef["database"]
          db_user = db_opscode_chef["username"]
          db_pass = db_opscode_chef["pass"]
          ocid_pass = db_opscode_chef["ocid_pass"]
          ocbifrost_pass = db_opscode_chef["ocbifrost_pass"]
          chefmover_pass = db_opscode_chef["chefmover_pass"]

          bash 'update_chef_db' do
            ignore_failure true
            #only_if { !node["chef-server"]["datastore_configured"] }
            code <<-EOH
                #Change erchef database configuration
                sed -i 's|{db_host,.*|{db_host, \"#{db_host}\"},|' #{chef_config_path}/opscode-erchef/sys.config
                sed -i 's|{db_port,.*|{db_port, #{db_port}},|' #{chef_config_path}/opscode-erchef/sys.config
                sed -i 's|{db_name,.*|{db_name, \"#{db_name}\"},|' #{chef_config_path}/opscode-erchef/sys.config
                sed -i 's|{db_user,.*|{db_user, \"#{db_user}\"},|' #{chef_config_path}/opscode-erchef/sys.config
                sed -i 's|{db_pass,.*|{db_pass, \"#{db_pass}\"},|' #{chef_config_path}/opscode-erchef/sys.config
                #Change oc_id configuration
                sed -i 's|{host:.*|{host: #{db_host}|' #{chef_config_path}/oc_id/config/database.yml
                sed -i 's|{port:.*|{port: #{db_port}|' #{chef_config_path}/oc_id/config/database.yml
                sed -i 's|{password:.*|{password: #{ocid_pass}|' #{chef_config_path}/oc_id/config/database.yml
                #Change oc_bifrost configuration
                sed -i 's|{db_host,.*|{db_host, \"#{db_host}\"},|' #{chef_config_path}/oc_bifrost/sys.config
                sed -i 's|{db_port,.*|{db_port, #{db_port}},|' #{chef_config_path}/oc_bifrost/sys.config
                sed -i 's|{db_pass,.*|{db_pass, \"#{ocbifrost_pass}\"},|' #{chef_config_path}/oc_bifrost/sys.config
                # Change chef-mover configuration
                sed -i 's|{db_host,.*|{db_host, \"#{db_host}\"},|' #{chef_config_path}/opscode-chef-mover/sys.config
                sed -i 's|{db_port,.*|{db_port, #{db_port}},|' #{chef_config_path}/opscode-chef-mover/sys.config
                sed -i 's|{db_pass,.*|{db_pass, \"#{chefmover_pass}\"},|' #{chef_config_path}/opscode-chef-mover/sys.config
              EOH
            action :run
          end
        end

        # S3 configuration
        s3_chef = Chef::DataBagItem.load("passwords", "s3") rescue s3_chef = {}
        if !s3_chef.empty?
          Chef::Log.info("Configuring Chef-server cookbook storage")
          s3_access_key_id = s3_chef["s3_access_key_id"]
          s3_secret_key_id = s3_chef["s3_secret_key_id"]
          s3_url= s3_chef["s3_url"]
          s3_external_url = s3_chef["s3_external_url"]
          s3_bucket = s3_chef["s3_bucket"]

          bash 'update_chef_s3' do
            ignore_failure true
            #only_if { !node["chef-server"]["datastore_configured"] }
            code <<-EOH
               sed -i 's|{s3_access_key_id,.*|{s3_access_key_id, \"#{s3_access_key_id}\"},|' #{chef_config_path}/opscode-erchef/sys.config
               sed -i 's|{s3_secret_key_id,.*|{s3_secret_key_id, \"#{s3_secret_key_id}\"},|' #{chef_config_path}/opscode-erchef/sys.config
               sed -i 's|{s3_url,.*|{s3_url, \"#{s3_url}\"},|' #{chef_config_path}/opscode-erchef/sys.config
               sed -i 's|{s3_external_url,.*|{s3_external_url, \"#{s3_external_url}\"},|' #{chef_config_path}/opscode-erchef/sys.config
               sed -i 's|{s3_platform_bucket_name,.*|{s3_platform_bucket_name, \"#{s3_bucket}\"},|' #{chef_config_path}/opscode-erchef/sys.config
               EOH
            action :run
          end
        end

        node.default["chef-server"]["datastore_configured"] = true
      end

      # Replace chef-server SV init script for systemd scripts
      # Stop current services
      execute 'Stopping default private-chef-server services' do
        command 'chef-server-ctl stop'
      end

      # Delete symbolic links of chef-server SV scripts
      node["chef-server"]["services_list"].each do |ln_file|
        link "/opt/opscode/service/#{ln_file}" do
          action :delete
        end
      end

      if chef_active
        node["chef-server"]["chef_middleware"].each do |srv|
          if srv.include? "opscode"
            service srv do
              action :start
            end
          else
            service "opscode-#{srv}" do
              action :start
            end
          end
        end
        # chef-services restart required
        execute "Restart chef-server services" do
          command 'for i in `s /opt/opscode/sv/ | sed "s/opscode-//g"`;do systemctl restart opscode-$i;done'
        end
      end
    else
      node.default["chef-server"]["installed"] = true
      node.default["chef-server"]["datastore_configured"] = true
    end

#TODO: Chef services configuration (erchef, solr4, etc...)

    if postgresql
      # call to postgresql resource
      chef_server_postgresql "Postgresql configuration" do
        memory postgresql_memory
        chef_active false
        srmode "master"
        netsync netsync
        virtual_ip postgresql_vip
        action :add
      end
    end

    Chef::Log.info("Chef-server cookbook has been processed")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin
    # TODO
    Chef::Log.info("Chef-server cookbook has been processed")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :register do
  begin
    consul_servers = system('serf members -tag consul=ready | grep consul=ready &> /dev/null')
    if !node["chef-server"]["registered"] and consul_servers
      query = {}
      query["ID"] = "erchef-#{node["hostname"]}"
      query["Name"] = "erchef"
      query["Address"] = "#{node["ipaddress"]}"
      query["Port"] = 4443
      json_query = Chef::JSONCompat.to_json(query)

      execute 'Register service in consul' do
         command "curl http://localhost:8500/v1/agent/service/register -d '#{json_query}' &>/dev/null"
         action :nothing
      end.run_action(:run)

      node.set["chef-server"]["registered"] = true
      Chef::Log.info("Chef services has been registered to consul")
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :deregister do
  begin
    consul_servers = system('serf members -tag consul=ready | grep consul=ready &> /dev/null')
    if node["chef-server"]["registered"] and consul_servers
      execute 'Deregister service in consul' do
        command "curl http://localhost:8500/v1/agent/service/deregister/erchef-#{node["hostname"]} &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.set["chef-server"]["registered"] = false
      Chef::Log.info("Chef services has been deregistered to consul")
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end
