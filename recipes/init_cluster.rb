
batch 'Initializing CouchBase cluster' do
  code <<-EOH
    "#{node['couchbase']['server']['cli_path']}" cluster-init -c #{node['fqdn']}:#{node['couchbase']['server']['port']} --cluster-init-username="#{node['couchbase']['server']['username']}" --cluster-init-password="#{node['couchbase']['server']['password']}" --cluster-init-ramsize=#{node['couchbase']['server']['memory_quota_mb']}
  EOH
end
