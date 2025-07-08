# Cookbook:: Chef-server
# Resource:: config

actions :add, :remove, :register, :deregister
default_action :add

attribute :memory, kind_of: Integer, default: 524288
attribute :postgresql, kind_of: [TrueClass, FalseClass], default: false
attribute :postgresql_memory, kind_of: Integer, default: 524288
attribute :postgresql_vip, kind_of: String
attribute :netsync, kind_of: String, default: '10.0.203.0/24'
attribute :chef_active, kind_of: [TrueClass, FalseClass], default: true
attribute :chef_config_path, kind_of: String, default: '/opt/opscode/embedded/service'
attribute :ipaddress, kind_of: String
attribute :s3_secrets, kind_of: Hash, default: {}
