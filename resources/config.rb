# Cookbook Name:: Chef-server
#
# Resource:: config
#

actions :add, :remove
default_action :add

attribute :memory, :kind_of => Fixnum, :default => 524288
attribute :postgresql, :kind_of => [TrueClass, FalseClass], :default => true
attribute :postgresql_memory, :kind_of => Fixnum, :default => 524288
attribute :chef_active, :kind_of => [TrueClass, FalseClass], :default => true
