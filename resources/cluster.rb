=begin
#<
This creates, configures, and manages clusters.

@action init Initialize a new cluster.
@action modify Modify existing cluster

@section Examples

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
#>
=end
resource_name :couchbase_cluster

# <
# @attribute admin_username The username of the admin account to create when \
# initializing or use for authentication when modifying
# >
property :admin_username, String, required: true
# <
# @attribute admin_password The password of the admin account to create when \
# initializing or use for authentication when modifying
# >
property :admin_password, String,
         required: true,
         callbacks: { 'must be at least six characters' => ->(x) { x.length } }
# <
# @attribute port The Web Administration Port to configure when initializing or \
# use for communication when modifying.
# >
property :port, Integer, default: 8091
# <
# @attribute memory_quota The RAM quota in MB for the Data service. May be a float \
# in the range 0..1 in which case it is calculated as a percentage of the node's \
# total memory.
# >
property :memory_quota, [Integer, Float],
         callbacks: {
             'must be an integer or be in the range ]0;1]' =>
                 -> (x) { x.is_a?(Integer) || (0.0 < x && x <= 1.0) }
         }
# <
# @attribute index_memory_quota The RAM quota in MB for the Index service. May be a \
# float in the range 0..1 in which case it is calculated as a percentage of the \
# node's total memory.
# >
property :index_memory_quota, [Integer, Float],
         callbacks: {
             'must be an integer or be in the range ]0;1]' =>
                 -> (x) { x.is_a?(Integer) || (0.0 < x && x <= 1.0) }
         }
couchbase_services = %w(data index query)
# <
# @attribute services Services that the Couchbase Server shall run. Valid services: \
# data, index, and query. Ignored when modifying.
# >
property :services, Array,
         default: %w(data),
         callbacks: {
             "contains invalid service(s) (valid services: #{couchbase_services})" =>
                 -> (x) { x.all? { |y| couchbase_services.include? y } }
         }
# <
# @attribute cluster_server_port The Web Administration port of a server in the \
# cluster to join.
# >
property :cluster_server_port, Integer
# <> @attribute cluster_server The hostname of a server in the cluster to join.
property :cluster_server, String
# <
# @attribute group_name The name of the group to which the node is added when \
# joining
# >
property :group_name, String
# <
# @attribute server_admin_username The username of the admin on the node to join \
# to the cluster. If not set, then admin_username is used.
# >
property :server_admin_username, String
# <
# @attribute server_admin_password The password of the admin on the node to join \
# to the cluster. If not set, then admin_password is used.
# >
property :server_admin_password, String
# <> @attribute rebalance Wether to rebalance when joining the node to the cluster.
property :rebalance, [TrueClass, FalseClass], default: false

default_action :init

load_current_value do |new_resource|
    if action == :join
        Chef::Log.warn new_resource.admin_username
        x = get_json '/pools/nodes',
                     user: new_resource.admin_username,
                     password: new_resource.admin_password,
                     host: new_resource.cluster_server_port,
                     port: new_resource.cluster_server_port
        already_in_cluster = x['nodes'].any? do |n|
            [node['ipaddress'], node['fqdn']].include? n['hostname'][0..-6]
        end
        current_value_does_not_exist! unless already_in_cluster
    end

    if new_resource.memory_quota.is_a? Float
        new_resource.memory_quota =
            (new_resource.memory_quota * node_total_memory_mb).to_i
    end
    if new_resource.index_memory_quota.is_a? Float
        new_resource.index_memory_quota =
            (new_resource.index_memory_quota * node_total_memory_mb).to_i
    end

    x = get_json '/pools/default/',
                 user: new_resource.admin_username,
                 password: new_resource.admin_password,
                 port: new_resource.port,
                 ignore_failure: true

    current_value_does_not_exist! if x.nil?

    memory_quota x['memoryQuota']
    index_memory_quota x['indexMemoryQuota']
end

action :init do
    unless @current_resource
        execute 'Initialize Couchbase cluster' do
            opts = {
                port: 8091,
                'cluster-username' => admin_username,
                'cluster-password' => admin_password
            }
            opts['cluster-ramsize'] = memory_quota if memory_quota
            opts['cluster-port'] = port
            opts['cluster-index-ramsize'] = index_memory_quota if index_memory_quota
            opts['services'] = services.join ',' if services

            command couchbase_cli('cluster-init', opts)
        end
        node.set['couchbase']['port'] = port
    end
end

action :modify do
    if @current_resource
        converge_if_changed :port, :memory_quota, :index_memory_quota do
            execute 'Update Couchbase cluster' do
                cmd = couchbase_cli('cluster-edit',
                                    port: port,
                                    user: admin_username,
                                    password: admin_password)
                cmd << "--cluster-ramsize=#{memory_quota} " if memory_quota
                if index_memory_quota
                    cmd << "--cluster-index-ramsize=#{index_memory_quota} "
                end
                command cmd
            end
        end
    end
end

action :join do
    unless @current_resource
        uid = new_resource.server_admin_username || new_resource.admin_username
        pwd = new_resource.server_admin_password || new_resource.admin_password

        execute 'Add server to cluster' do
            command couchbase_cli('server-add',
                                  port: cluster_server_port,
                                  user: admin_username,
                                  password: admin_password,
                                  host: cluster_server,
                                  'server-add' => "#{node['fqdn']}:#{port}",
                                  'group-name' => group_name,
                                  'server-add-username' => uid,
                                  'server-add-password' => pwd,
                                  'services' => services ? services.join(',') : nil)
        end

        execute 'Rebalance cluster' do
            command couchbase_cli('rebalance',
                                  user: uid,
                                  password: pwd)
            only_if { rebalance }
        end
    end
end
