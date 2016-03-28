# Description

Installs and configures Couchbase.

# Requirements

## Platform:

* debian

## Cookbooks:

* chef-vault

# Attributes

* `node['couchbase']['version']` - The version of Couchbase to install. Defaults to `4.1.0`.
* `node['couchbase']['edition']` - The edition of Couchbase to install. Defaults to `enterprise`.
* `node['couchbase']['cluster_search_query']` - Chef search query used to find a Couchbase cluster to join. Defaults to `chef_environment:#{node.chef_environment} AND recipes:chef-couchbase\:\:node`.
* `node['couchbase']['install_path']` - Chef search query used to find a Couchbase cluster to join. Defaults to `chef_environment:#{node.chef_environment} AND recipes:chef-couchbase\:\:node`.

# Recipes

* chef-couchbase::install
* chef-couchbase::node

# Resources

* [couchbase_cluster](#couchbase_cluster) - This creates, configures, and manages clusters.
* [couchbase_node](#couchbase_node)

## couchbase_cluster

This creates, configures, and manages clusters.

### Actions

- init: Initialize a new cluster. Default action.
- join:
- modify: Modify existing cluster

### Attribute Parameters

- admin_username:
- admin_password:
- port:  Defaults to <code>8091</code>.
- memory_quota:
- index_memory_quota:
- services:  Defaults to <code>["data"]</code>.
- cluster_server_port:
- cluster_server:
- group_name:
- server_admin_username:
- server_admin_password:
- rebalance:  Defaults to <code>false</code>.

### Examples

    # Create a cluster
    couchbase_cluster 'default' do
        admin_username     'Admninistrator'
        admin_pasword      'password'
        port               8091
        memory_quota       512
        index_memory_quota 256
        services %w(data index query)
    end

    # Create a cluster and use 50% of the node's memory for Data service and 30% for
    #  the Index service
    couchbase_cluster 'default' do
        admin_username     'Admninistrator'
        admin_pasword      'password'
        port               8091
        memory_quota       0.5
        index_memory_quota 0.3
        services %w(data index query)
    end

    # Change the memory quota for the Data service
    couchbase_cluster 'default' do
        admin_username 'Admninistrator'
        admin_pasword  'password'
        memory_quota   1024
    end

## couchbase_node

This installs Couchbase and configures a node

### Actions

- modify: Change Default action.

### Attribute Parameters

- admin_username:
- admin_password:
- port:  Defaults to <code>8091</code>.
- id:
- log_dir:
- data_path:
- index_path:
- hostname:

# License and Maintainer

Maintainer:: Simon Bang Terkildsen (<terkildsen@monsenso.com>)

License:: MIT
