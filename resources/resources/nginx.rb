# Cookbook:: Chef-server
# Resource:: nginx

actions :add, :remove
default_action :add

attribute :memory, kind_of: Integer, default: 524288
