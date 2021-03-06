#
# Cookbook Name:: couchbase
# Recipe:: server
#
# Copyright 2012, getaroom
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

if node['couchbase']['server']['cluster-init-server'].nil? || node['couchbase']['server']['cluster-init-server'].empty? then
  throw 'No cluster-init-server set!'
end

username = ""
password = ""

if node['couchbase']['server']['databag'].nil? || node['couchbase']['server']['databag'].empty?
  username = node['couchbase']['server']['username']
  password = node['couchbase']['server']['password']
else
  users = Chef::EncryptedDataBagItem.load(node['couchbase']['server']['databag'], node['couchbase']['server']['databag_name'])
  couchbase_credentials = users["couchbase"]

  username = couchbase_credentials['username']
  password = couchbase_credentials['password']
end

allready_configured = CouchbaseHelper.is_configured?(node['couchbase']['server']['cli_path'], node['fqdn'], username, password)

remote_file File.join(Chef::Config[:file_cache_path], node['couchbase']['server']['package_file']) do
  source node['couchbase']['server']['package_full_url']
  action :create_if_missing
end

template "#{Chef::Config[:file_cache_path]}/setup_#{node['couchbase']['server']['version']}.iss" do
  source "setup_#{node['couchbase']['server']['version']}.iss.erb"
  action :create
end

windows_package "Couchbase Server" do
  source File.join(Chef::Config[:file_cache_path], node['couchbase']['server']['package_file'])
  options "/s /f1#{Chef::Config[:file_cache_path]}/setup_#{node['couchbase']['server']['version']}.iss"
  installer_type :custom
  action :install
end

ruby_block "block_until_operational" do
  block do
    Chef::Log.info "Waiting until Couchbase is listening on port #{node['couchbase']['server']['port']}"
    until CouchbaseHelper.service_listening?(node['couchbase']['server']['port'], node['platform']) do
      sleep 1
      Chef::Log.debug(".")
    end

    Chef::Log.info "Waiting until the Couchbase admin API is responding"
    test_url = URI.parse("http://localhost:#{node['couchbase']['server']['port']}")
    until CouchbaseHelper.endpoint_responding?(test_url) do
      sleep 1
      Chef::Log.debug(".")
    end
  end
  action :nothing
end

service "CouchbaseServer" do
  supports :restart => true, :status => true
  action [:enable, :start]
  notifies :create, "ruby_block[block_until_operational]", :immediately
  not_if {allready_configured}
end

directory node['couchbase']['server']['log_dir'] do
  recursive true
  not_if {allready_configured}
end

ruby_block "rewrite_couchbase_log_dir_config" do
  log_dir_line = %{{error_logger_mf_dir, "#{node['couchbase']['server']['log_dir']}"}.}
  static_config_file = ::File.join(node['couchbase']['server']['install_dir'], 'etc', 'couchbase', 'static_config')

  block do
    file = Chef::Util::FileEdit.new(static_config_file)
    file.search_file_replace_line(/error_logger_mf_dir/, log_dir_line)
    file.write_file
  end

  notifies :restart, "service[CouchbaseServer]", :immediately
  not_if {allready_configured}
end

directory node['couchbase']['server']['database_path'] do
  recursive true
  not_if {allready_configured}
end

directory node['couchbase']['server']['index_path'] do
  recursive true
  not_if {allready_configured}
end

ruby_block 'Setting CouchBase data and index path' do
  cli_path = node['couchbase']['server']['cli_path']
  fqdn = node['fqdn']
  port = node['couchbase']['server']['port']
  data_path = node['couchbase']['server']['database_path']
  index_path = node['couchbase']['server']['index_path']

  block do
    CouchbaseHelper.set_data_and_index_path(cli_path, fqdn, port, data_path, index_path)
  end
  not_if {allready_configured}
end

ruby_block 'Add node to CouchBase cluster and rebalance' do
  cli_path = node['couchbase']['server']['cli_path']
  cluster = node['couchbase']['server']['cluster-init-server']
  fqdn = node['fqdn']
  port = node['couchbase']['server']['port']

  ramsize = node['couchbase']['server']['memory_quota_mb']

  if node['fqdn'].casecmp("#{node['couchbase']['server']['cluster-init-server']}") == 0
    block do
      CouchbaseHelper.init_cluster(cli_path, cluster, port, username, password, ramsize)
    end
    not_if {allready_configured}
  else
    block do
      CouchbaseHelper.add_server(cli_path, cluster, port, fqdn, username, password)
    end
    not_if {allready_configured}
  end
end