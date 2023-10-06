# Cookbook Name:: Chef-server
#
# Resource:: postgresql
#

actions :add, :remove
default_action :add

attribute :memory, :kind_of => Fixnum, :default => 524288
attribute :user, :kind_of => String, :default => "opscode"
attribute :group, :kind_of => String, :default => "opscode"
attribute :chef_active, :kind_of => [TrueClass, FalseClass], :default => false