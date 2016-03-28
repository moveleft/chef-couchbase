include_recipe 'chef-couchbase::install'
include_recipe 'chef-vault'

%w(log_dir data_path index_path).each do |dir|
    directory node['couchbase'][dir] do
        owner node['couchbase']['owner']
        group node['couchbase']['group']
        mode 0755
        recursive true
    end
end

secret = chef_vault_item(node['couchbase']['vault'], node['couchbase']['vault_item'])

uid = secret['admin_username']
pwd = secret['admin_password']

couchbase_node 'self' do
    admin_username uid
    admin_password uid
    hostname node['couchbase']['hostname'] || node['fqdn']
    log_dir node['couchbase']['log_dir']
    data_path node['couchbase']['data_path']
    index_path node['couchbase']['index_path']
    action :modify
end

cluster_nodes = search(:node, node['couchbase']['cluster_search_query'])
                .select do |x|
                    ipaddress = x['ipaddress']
                    ipaddress = ipaddress.last if ipaddress.is_a? Array
                    ipaddress != node['ipaddress']
                end

if cluster_nodes.empty?
    couchbase_cluster 'Initialize cluster' do
        admin_username uid
        admin_password pwd
        memory_quota 330
        index_memory_quota 330
        services %w(data index query)
    end
else
    cluster_server_port =
        cluster_nodes[0]['couchbase'] ? cluster_nodes[0]['couchbase']['port'] : 8091

    couchbase_cluster 'Join cluster' do
        admin_username uid
        admin_password pwd
        services %w(data index query)
        cluster_server_port cluster_server_port
        cluster_server cluster_nodes[0]['fqdn']
        rebalance true
        action :join
    end
end
