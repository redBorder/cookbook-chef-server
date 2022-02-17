# Cookbook Name:: Chef-server
#
# Resource:: postgresql
#

actions :add, :remove
default_action :add

attribute :memory, :kind_of => Fixnum, :default => 524288
attribute :datadir, :kind_of => String, :default => "/var/opt/opscode/rabbitmq/"
attribute :user, :kind_of => String, :default => "opscode"
attribute :group, :kind_of => String, :default => "opscode"
