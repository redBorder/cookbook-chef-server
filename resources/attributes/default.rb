default['chef-server']['services']['chef'] = true
default['chef-server']['services']['nginx'] = true
default['chef-server']['services']['postgresql'] = true
default['chef-server']['chef_middleware'] = %w(bookshelf oc_bifrost oc_id opscode-erchef redis_lb opensearch)
default['chef-server']['services_list'] = %w(postgresql nginx bookshelf oc_bifrost oc_id opscode-erchef redis_lb opensearch)
default['chef-server']['services_dir'] = '/opt/opscode/service'

# flags
default['chef-server']['installed'] = false
default['chef-server']['datastore_configured'] = false
default['chef-server']['registered'] = false
