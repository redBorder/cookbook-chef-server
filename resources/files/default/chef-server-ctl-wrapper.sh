#!/bin/bash
# Run chef-server-ctl with its embedded Ruby, isolated from the RVM environment
unset GEM_HOME GEM_PATH GEM_ROOT RUBYOPT RUBYLIB RUBY_VERSION MY_RUBY_HOME IRBRC
unset BUNDLE_GEMFILE BUNDLE_PATH BUNDLE_BIN_PATH
export PATH=/opt/opscode/embedded/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
exec /opt/opscode/bin/chef-server-ctl "$@"
