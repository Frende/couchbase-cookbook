#
# Cookbook Name:: couchbase
# Library:: helper
#
# Author:: Seth Chisamore <schisamo@opscode.com>
# Author:: Julian Dunn <jdunn@opscode.com>
#
# Copyright 2013, Opscode, Inc.
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

# Shamelessly stolen from Opscode's jenkins cookbook. Works for now.

require 'chef/mixin/shell_out'
require 'net/http'

module CouchbaseHelper
  extend Chef::Mixin::ShellOut

  def self.service_listening?(port, platform)
    case platform
    when "windows"
      netstat_command = "netstat -nt"
    else
      netstat_command = "netstat -lnt"
    end
    
    cmd = shell_out!(netstat_command)
    Chef::Log.debug("`#{netstat_command}` returned: \n\n #{cmd.stdout}")

    cmd.stdout.each_line.select do |l|
      case platform
      when "windows"
        l.split[1] =~ /#{port}/
      else
        l.split[3] =~ /#{port}/
      end
    end.any?
  end

  def self.endpoint_responding?(url)
    # XXX Should probably not use Chef::REST for this. Chef::REST only
    # Accepts application/json; why not just use Net::HTTP directly?
    # response = Chef::REST::RESTRequest.new(:GET, url, nil).call
    begin
      uri = URI(url);
      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess) ||
            response.kind_of?(Net::HTTPRedirection) ||
            response.kind_of?(Net::HTTPForbidden)
        Chef::Log.info("GET to #{url} successful")
        return true
      else
        Chef::Log.info("GET to #{url} returned #{response.code} / #{response.message}")
        return false
      end
    rescue EOFError, Net::HTTPBadResponse, Errno::ECONNREFUSED
      Chef::Log.info("Failed to connect to #{url}.")
      return false
    end
  end

  def self.is_configured?(cli_path, fqdn, user, pass)
    Chef::Log.info("Checking if cluster can be contacted locally...")
    cmd_string = "\"#{cli_path}\" server-list -c #{fqdn} -u \"#{user}\" -p \"#{pass}\""
    begin
      cmd = shell_out!(cmd_string)
      Chef::Log.info("Cluster successfully contacted.")
      return true
    rescue
      Chef::Log.info("Failed to contact cluster.")
      return false
    end
  end 

  def self.set_data_and_index_path(cli_path, fqdn, port, data_path, index_path)
    cmd_string = "\"#{cli_path}\" node-init -c #{cluster}:#{port} --node-init-data-path=\"#{data_path}\" --node-init-index-path=\"#{index_path}\""
    cmd = shell_out!(cmd_string, :returns => [0,-1073740777])
    Chef::Log.info("`#{cmd_string}` returned: \n\n #{cmd.stdout}")
  end

  def self.add_server(cli_path, cluster, port, fqdn, user, pass)
    cmd_string = "\"#{cli_path}\" rebalance -c #{cluster}:#{port} --server-add=#{fqdn} --server-add-username=\"#{user}\" --server-add-password=\"#{pass}\" -u \"#{user}\" -p \"#{pass}\""
    cmd = shell_out!(cmd_string, :returns => [0,-1073740777])
    Chef::Log.info("`#{cmd_string}` returned: \n\n #{cmd.stdout}")
  end 

  def self.init_cluster(cli_path, cluster, port, user, pass, ramsize)
    cmd_string = "\"#{cli_path}\" cluster-init -c #{cluster}:#{port} --cluster-init-username=\"#{user}\" --cluster-init-password=\"#{pass}\" --cluster-init-ramsize=#{ramsize}"
    cmd = shell_out!(cmd_string, :returns => [0])
    Chef::Log.info("`#{cmd_string}` returned: \n\n #{cmd.stdout}")
  end 
end
