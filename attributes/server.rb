#
# Cookbook Name:: couchbase
# Attributes:: server
#
# Author:: Julian C. Dunn (<jdunn@opscode.com>)
# Copyright (C) 2012, SecondMarket Labs, LLC.
# Copyright (C) 2013, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package_machine = node['kernel']['machine'] == "x86_64" ? "x86_64" : "x86"

default['couchbase']['server']['edition'] = "community"
default['couchbase']['server']['version'] = "2.2.0"
default['couchbase']['server']['cluster-init-server'] = ""

if node['kernel']['machine'] != 'x86_64' && node['couchbase']['server']['version'] == "2.0.0"
  Chef::Log.error("Couchbase Server 2.0.0 on Windows must be installed on a 64-bit machine. Later versions have support for x86.")
elsif ["2.0.0", "2.0.1", "2.1.0", "2.1.1"].include? node['couchbase']['server']['version']
  default['couchbase']['server']['package_file'] = "couchbase-server-#{node['couchbase']['server']['edition']}_#{package_machine}_#{node['couchbase']['server']['version']}.setup.exe"
else
  default['couchbase']['server']['package_file'] = "couchbase-server-#{node['couchbase']['server']['edition']}_#{node['couchbase']['server']['version']}_#{package_machine}.setup.exe"
end

default['couchbase']['server']['package_base_url'] = "http://packages.couchbase.com/releases/#{node['couchbase']['server']['version']}"
default['couchbase']['server']['package_full_url'] = "#{node['couchbase']['server']['package_base_url']}/#{node['couchbase']['server']['package_file']}"

default['couchbase']['server']['install_dir'] = File.join("C:","Program Files","Couchbase","Server")

default['couchbase']['server']['cli_cmd'] = "couchbase-cli.exe"
default['couchbase']['server']['cli_dir'] = File.join(node['couchbase']['server']['install_dir'], "bin")
default['couchbase']['server']['cli_path'] = File.join(node['couchbase']['server']['cli_dir'], node['couchbase']['server']['cli_cmd'])

default['couchbase']['server']['database_path'] = File.join(node['couchbase']['server']['install_dir'],"var","lib","couchbase","data")
default['couchbase']['server']['index_path'] = File.join(node['couchbase']['server']['install_dir'],"var","lib","couchbase","index")
default['couchbase']['server']['log_dir'] = File.join(node['couchbase']['server']['install_dir'],"var","lib","couchbase","logs")

default['couchbase']['server']['databag'] = ""
default['couchbase']['server']['databag_name'] = ""

default['couchbase']['server']['username'] = "Administrator"
default['couchbase']['server']['password'] = nil

default['couchbase']['server']['memory_quota_mb'] = Couchbase::MaxMemoryQuotaCalculator.from_node(node).in_megabytes

default['couchbase']['server']['port'] = 8091

default['couchbase']['server']['allow_unsigned_packages'] = true