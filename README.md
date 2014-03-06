Description
===========

Installs and configures Couchbase. This is a stripped down Windows specific version forked from https://github.com/urbandecoder/couchbase 

Requirements
============

Chef 0.10.10 and Ohai 0.6.12 are required due to the use of platform_family.

Platforms
---------

* Microsoft Windows

Supported Couchbase versions
----------------------------

* 2.0.0 
* 2.0.1
* 2.1.0
* 2.1.1
* 2.2.0 

To add support for future version, a Ruby template file must be added to the cookbook. This is because (unfortunatly) the Couchbase installer is using a InstallShield Response File with unique GUID's in it, that's impossible for this cookbook to generate. However, to generate one yourself do the following:

1. Download the version of Couchbase you want to install
2. On a Windows OS, run your installer with the following command: `couchbase-server-xxx.setup.exe /r /f1setup_major.minor.build.iss`
3. Complete the installation wizard
4. Copy the generated .iss file found in `C:\Windows\` into this repo under `templates/default/` (remember to add the `.erb` extension)
5. A pull request for the change you just made would be greatly appreciated  

Attributes
==========

couchbase-server
----------------

* `node['couchbase']['server']['edition']`              - The edition of couchbase-server to install, "community" or "enterprise"
* `node['couchbase']['server']['version']`              - The version of couchbase-server to install
* `node['couchbase']['server']['cluster-init-server']`  - If multiple servers are installed into a cluster, this is the first server that's
                                                          responsible for clearing the cluster
* `node['couchbase']['server']['package_file']`         - The couchbase-server package file to download and install
* `node['couchbase']['server']['package_base_url']`     - The url path to download the couchbase-server package file from
* `node['couchbase']['server']['package_full_url']`     - The full url to the couchbase-server package file to download and install
* `node['couchbase']['server']['install_dir']`          - The install location for the couchbase server (default `C:\Program Files\Couchbase\Server\`)
* `node['couchbase']['server']['database_path']`        - The directory Couchbase should persist data to (default `C:\Program Files\Couchbase\Server\var\lib\couchbase\data`)
* `node['couchbase']['server']['index_path']`           - The directory Couchbase should index data to (default `C:\Program Files\Couchbase\Server\var\lib\couchbase\index`)
* `node['couchbase']['server']['log_dir']`              - The directory Couchbase should log to (default `C:\Program Files\Couchbase\Server\var\lib\couchbase\logs`)
* `node['couchbase']['server']['memory_quota_mb']`      - The per server RAM quota for the entire cluster in megabytes
                                                          defaults to Couchbase's maximum allowed value
* `node['couchbase']['server']['allow_unsigned_packages']` - Whether to allow Couchbase's unsigned packages to be installed (default to 'true')

Credentials
-----------

Use:

* `node['couchbase']['server']['username']`             - The cluster's username for the REST API and Admin UI
* `node['couchbase']['server']['password']`             - The cluster's password for the REST API and Admin UI

Or point to a data_bag:

* `node['couchbase']['server']['databag']`              - Databag (e.g. service_users)
* `node['couchbase']['server']['databag_name']`         - Databag name inside databag (e.g. prod_env)

Example of data_bag usage
-------------------------

databag: service_users

databag_name : prod

With the above databag, the couchbase cookbook expects the following structure for the databag definition: 

```json
{
  "id": "prod",
  "couchbase": {
    "username": "Administrator",
    "password": "password"
  }
}
```

Recipes
=======

server
------

Installs the couchbase-server package and starts the couchbase-server service.

Resources/Providers
===================

couchbase_node
--------------

### Actions

* `:modify` - **Default** Modify the configuration of the node

### Attribute Parameters

* `id` - The id of the Couchbase node, typically "self", defaults to the resource name
* `database_path` - The directory the Couchbase node should persist data to
* `username` - The username to use to authenticate with Couchbase
* `password` - The password to use to authenticate with Couchbase

### Examples

```ruby
couchbase_node "self" do
  database_path "/mnt/couchbase-server/data"

  username "Administrator"
  password "password"
end
```

couchbase_cluster
-----------------

### Actions

* `:create_if_missing` - **Default** Create a cluster/pool only if it doesn't exist yet

### Attribute Parameters

* `cluster` - The id of the Couchbase cluster, typically "default", defaults to the resource name
* `memory_quota_mb` - The per server RAM quota for the entire cluster in megabytes
* `username` - The username to use to authenticate with Couchbase
* `password` - The password to use to authenticate with Couchbase

### Examples

```ruby
couchbase_cluster "default" do
  memory_quota_mb 256

  username "Administrator"
  password "password"
end
```

couchbase_settings
------------------

### Actions

* `:modify` - **Default** Modify the collection of settings

### Attribute Parameters

* `group` - Which group of settings to modify, defaults to the resource name
* `settings` - The hash of settings to modify
* `username` - The username to use to authenticate with Couchbase
* `password` - The password to use to authenticate with Couchbase

### Examples

```ruby
couchbase_settings "autoFailover" do
  settings({
    "enabled" => true,
    "timeout" => 30,
  })

  username "Administrator"
  password "password"
end
```

Roadmap
=======

* Many of the heavyweight resources/providers need to be moved to LWRPs.

If you have time to work on these things or to improve the cookbook in other ways, please submit a pull request.

License and Author
==================

* Author:: Chris Griego (<cgriego@getaroom.com>)
* Author:: Morgan Nelson (<mnelson@getaroom.com>)
* Author:: Julian Dunn (<jdunn@aquezada.com>)
* Author:: Enrico Stahn (<mail@enricostahn.com>)

* Copyright:: 2012, getaroom
* Copyright:: 2012, SecondMarket Labs, LLC.
* Copyright:: 2013, Opscode, Inc.
* Copyright:: 2013, Zanui

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
