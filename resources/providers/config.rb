# Cookbook:: Chef-server
# Provider:: chef

action :add do
  begin
    chef_active = new_resource.chef_active
    postgresql = new_resource.postgresql
    postgresql_memory = new_resource.postgresql_memory
    postgresql_vip = new_resource.postgresql_vip
    netsync = new_resource.netsync
    chef_config_path = new_resource.chef_config_path
    s3_secrets = new_resource.s3_secrets

    link '/root/chef' do
      to '/var/chef'
      action ::File.directory?('/var/chef') ? :create : :delete
    end

    # Only executed if it's a custom node with chef-server
    if !::File.directory?('/opt/opscode') && !node['chef-server']['installed']

      Chef::Log.info('Installing chef services')
      # install chef-server package
      dnf_package 'redborder-chef-server' do
        action :upgrade
      end

      execute 'Set 4443 as chef proxy SSL default port' do
        command 'echo "nginx[\'ssl_port\'] = 4443" >> /etc/opscode/chef-server.rb'
      end

      execute 'Set 4080 as chef proxy non SSL default port' do
        command 'echo "nginx[\'non_ssl_port\'] = 4080" >> /etc/opscode/chef-server.rb'
      end

      # chef-server reconfigure
      execute 'Configuring chef-server' do
        command '/usr/bin/chef-server-ctl reconfigure --chef-license=accept &>> /root/.install-chef-server.log'
      end

      file '/etc/opscode/private-chef-secrets.json' do
        owner 'opscode'
        group 'opscode'
        mode '0600'
        action :touch
        only_if { ::File.exist?('/etc/opscode/private-chef-secrets.json') }
        # notifies :restart, 'service[opscode-erchef]', :immediately # TODO: Check if this was needed or not
      end

      # stop chef-server services
      execute 'Stopping default private-chef-server services' do
        command 'chef-server-ctl graceful-kill'
      end

      # Chef-server installation finished
      node.default['chef-server']['installed'] = true

      # Chef server datastore configuration
      unless node['chef-server']['datastore_configured']
        # Load Database configuration
        begin
          db_opscode_chef = data_bag_item('passwords', 'db_opscode_chef')
        rescue
          db_opscode_chef = {}
        end

        unless db_opscode_chef.empty?
          Chef::Log.info('Configuring Chef-server database')
          db_host = db_opscode_chef['hostname']
          db_port = db_opscode_chef['port']
          db_name = db_opscode_chef['database']
          db_user = db_opscode_chef['username']
          db_pass = db_opscode_chef['pass']
          ocid_pass = db_opscode_chef['ocid_pass']
          ocbifrost_pass = db_opscode_chef['ocbifrost_pass']
          chefmover_pass = db_opscode_chef['chefmover_pass']

          bash 'update_chef_db' do
            ignore_failure true
            code <<-EOH
                # Change erchef database configuration
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
                # sed -i 's|{db_host,.*|{db_host, \"#{db_host}\"},|' #{chef_config_path}/opscode-chef-mover/sys.config
                # sed -i 's|{db_port,.*|{db_port, #{db_port}},|' #{chef_config_path}/opscode-chef-mover/sys.config
                # sed -i 's|{db_pass,.*|{db_pass, \"#{chefmover_pass}\"},|' #{chef_config_path}/opscode-chef-mover/sys.config
              EOH
            action :run
          end
        end

        unless s3_secrets.empty?
          Chef::Log.info('Configuring Chef-server cookbook storage')
          s3_access_key_id = s3_secrets['s3_access_key_id']
          s3_secret_key_id = s3_secrets['s3_secret_key_id']
          s3_url           = s3_secrets['s3_url']
          s3_bucket        = s3_secrets['s3_bucket']

          bash 'update_chef_s3' do
            ignore_failure true
            code <<-EOH
               sed -i 's|{s3_access_key_id,.*|{s3_access_key_id, \"#{s3_access_key_id}\"},|' #{chef_config_path}/opscode-erchef/sys.config
               sed -i 's|{s3_secret_key_id,.*|{s3_secret_key_id, \"#{s3_secret_key_id}\"},|' #{chef_config_path}/opscode-erchef/sys.config
               sed -i 's|{s3_url,.*|{s3_url, \"#{s3_url}\"},|' #{chef_config_path}/opscode-erchef/sys.config
               sed -i 's|{s3_external_url,.*|{s3_external_url, \"#{s3_url}\"},|' #{chef_config_path}/opscode-erchef/sys.config
               sed -i 's|{s3_platform_bucket_name,.*|{s3_platform_bucket_name, \"#{s3_bucket}\"},|' #{chef_config_path}/opscode-erchef/sys.config
               EOH
            action :run
          end
        end

        node.default['chef-server']['datastore_configured'] = true
      end

      # Replace chef-server SV init script for systemd scripts
      # Stop current services
      execute 'Stopping default private-chef-server services' do
        command 'chef-server-ctl stop'
      end

      # Delete symbolic links of chef-server SV scripts
      node['chef-server']['services_list'].each do |ln_file|
        link "/opt/opscode/service/#{ln_file}" do
          action :delete
        end
      end

      if chef_active
        node['chef-server']['chef_middleware'].each do |srv|
          if srv.include?('opscode')
            service srv do
              action :start
            end
          else
            service "opscode-#{srv}" do
              action :start
            end
          end
        end
        if postgresql
          # chef-services restart required (with opscode-postgresql)
          execute 'Restart chef-server services' do
            command 'for i in `ls /opt/opscode/sv/ | sed "s/opscode-//g"`;do systemctl restart opscode-$i;done'
          end
        else
          # chef-services restart required (without opscode-postgresql)
          execute 'Restart chef-server services' do
            command 'for i in `ls /opt/opscode/sv/ | sed "s/opscode-//g | grep -v postgresql"`;do systemctl restart opscode-$i;done'
          end
        end
      end
    else
      node.default['chef-server']['installed'] = true
      node.default['chef-server']['datastore_configured'] = true
    end

    # Change default permissions of crt file needed by webui (644)
    file "/root/.chef/trusted_certs/#{node['hostname']}.crt" do
      owner 'root'
      group 'root'
      mode '0644'
      action :touch
      only_if { ::File.exist?("/root/.chef/trusted_certs/#{node['hostname']}.crt") }
    end

    # TODO: Chef services configuration (erchef, etc...)
    if postgresql
      # call to postgresql resource
      chef_server_postgresql 'Postgresql configuration' do
        memory postgresql_memory
        chef_active false
        srmode 'master'
        netsync netsync
        virtual_ip postgresql_vip
        action :add
      end
    end

    Chef::Log.info('Chef-server cookbook has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin
    Chef::Log.info('Chef-server cookbook has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :register do
  begin
    ipaddress = new_resource.ipaddress
    consul_servers = system('serf members -tag consul=ready | grep consul=ready &> /dev/null')
    unless node['chef-server']['registered'] && consul_servers
      query = {}
      query['ID'] = "erchef-#{node['hostname']}"
      query['Name'] = 'erchef'
      query['Address'] = ipaddress
      query['Port'] = 4443
      json_query = Chef::JSONCompat.to_json(query)

      execute 'Register service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/register -d '#{json_query}' &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.normal['chef-server']['registered'] = true
      Chef::Log.info('Chef services has been registered to consul')
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :deregister do
  begin
    consul_servers = system('serf members -tag consul=ready | grep consul=ready &> /dev/null')
    if node['chef-server']['registered'] && consul_servers
      execute 'Deregister service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/deregister/erchef-#{node['hostname']} &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.normal['chef-server']['registered'] = false
      Chef::Log.info('Chef services has been deregistered to consul')
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end
