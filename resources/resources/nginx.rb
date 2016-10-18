# Cookbook Name:: Chef-server
#
# Resource:: nginx
#

actions :add, :remove
default_action :add

attribute :memory, :kind_of => Fixnum, :default => 524288

