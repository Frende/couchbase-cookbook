batch 'Add node to CouchBase cluster and rebalance' do
  code <<-EOH
    "#{node['couchbase']['server']['cli_path']}" rebalance -c #{node['couchbase']['server']['cluster-init-server']}:#{node['couchbase']['server']['port']} --server-add=#{node['fqdn']} -u "#{node['couchbase']['server']['username']}" -p "#{node['couchbase']['server']['password']}"
  EOH
end
