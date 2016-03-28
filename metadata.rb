name             'chef-couchbase'
maintainer       'Simon Bang Terkildsen'
maintainer_email 'terkildsen@monsenso.com'
license          'MIT'
description      'Installs and configures Couchbase.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

%w(debian).each do |os|
    supports os
end

depends 'chef-vault'

attribute 'couchbase/version',
          display_name: 'Couchbase version',
          description: 'The version of Couchbase to install',
          type: 'string',
          required: 'recommended',
          recipes: [],
          default: '4.1.0'

attribute 'couchbase/edition',
          display_name: 'Couchbase edition',
          description: 'The edition of Couchbase to install',
          type: 'string',
          required: 'recommended',
          recipes: [],
          default: 'enterprise'

attribute 'couchbase/cluster_search_query',
          display_name: 'Cluster search query',
          description: 'Chef search query used to find a Couchbase cluster to join',
          type: 'string',
          required: 'recommended',
          recipes: [],
          default: 'chef_environment:#{node.chef_environment} AND ' \
                   'recipes:chef-couchbase\:\:node'
