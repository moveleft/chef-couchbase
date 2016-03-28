default['couchbase']['version'] = '4.1.0'
default['couchbase']['edition'] = 'enterprise'
default['couchbase']['cluster_search_query'] =
    "chef_environment:#{node.chef_environment} AND recipes:chef-couchbase\\:\\:node"
default['couchbase']['vault'] = 'couchbase'
default['couchbase']['vault_item'] = 'couchbase'

default['couchbase']['service_name'] = 'couchbase-server'
default['couchbase']['log_dir'] = '/var/log/couchbase'
default['couchbase']['data_path'] = '/var/lib/couchbase/data'
default['couchbase']['index_path'] = '/var/lib/couchbase/index'
default['couchbase']['owner'] = 'couchbase'
default['couchbase']['group'] = 'couchbase'
default['couchbase']['install_path'] = '/opt/couchbase'
