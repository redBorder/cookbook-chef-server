# Cookbook Name:: Chef-server
#
# Resource:: config
#

actions :add, :remove, :register, :deregister
default_action :add

attribute :memory, :kind_of => Fixnum, :default => 524288
attribute :rabbitmq, :kind_of => [TrueClass, FalseClass], :default => true
attribute :rabbitmq_memory, :kind_of => Fixnum, :default => 524288
attribute :postgresql, :kind_of => [TrueClass, FalseClass], :default => true
attribute :postgresql_memory, :kind_of => Fixnum, :default => 524288
attribute :postgresql_vip, :kind_of => String
attribute :netsync, :kind_of => String, :default => "10.0.203.0/24"
attribute :chef_active, :kind_of => [TrueClass, FalseClass], :default => true
attribute :chef_config_path, :kind_of => String, :default => "/var/opt/opscode"
