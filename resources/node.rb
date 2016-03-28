=begin
#<
This installs Couchbase and configures a node

@action modify Change

#>
=end
resource_name :couchbase_node

# <> @attribute admin_username The username of the admin account.
property :admin_username, String, required: true
# <> @attribute admin_password The password of the admin account.
property :admin_password, String, required: true
# <> @attribute port The Web Admninistrator port
property :port, Integer, default: 8091
# <> @attribute id The id of the node, used to retrieve information.
property :id, String, name_property: true
# <> @attribute log_dir Path to a directory where Couchbase should store it's logs.
property :log_dir, String
# <> @attribute data_path Path to a directory where Couchbase should store data.
property :data_path, String
# <
# @attribute data_path Path to a directory where Couchbase should store the view \
# index.
# >
property :index_path, String
# <> @attribute hostname The host name of the node.
property :hostname, String

default_action :modify

# knife-cookbook-doc workaround
install_path = node ? node['couchbase']['install_path'] : ''

static_config_file = ::File.join(install_path,
                                 'etc', 'couchbase', 'static_config')

load_current_value do |new_resource|
    current_value_does_not_exist! unless ::File.exist?(static_config_file)

    m = /{error_logger_mf_dir, "(.+?)"}./.match(::File.read(static_config_file))
    log_dir m[1]

    x = get_json "/nodes/#{id}",
                 user: new_resource.admin_username,
                 password: new_resource.admin_password,
                 port: new_resource.port
    data_path x['storage']['hdd'][0]['path']
    index_path x['storage']['hdd'][0]['index_path']
end

action :modify do
    converge_if_changed :log_dir do
        ruby_block 'Set Couchbase log dir' do
            log_dir_line = %({error_logger_mf_dir, "#{log_dir}"}.)

            block do
                file = Chef::Util::FileEdit.new(static_config_file)
                file.search_file_replace_line(/error_logger_mf_dir/, log_dir_line)
                file.write_file
            end
            only_if do
                ::File.readlines(static_config_file).grep(/#{log_dir_line}/).empty?
            end
        end
    end

    converge_if_changed :data_path, :index_path, :hostname do
        execute 'Initialize node' do
            command couchbase_cli('node-init', user: admin_username,
                                               password: admin_password,
                                               'node-init-data-path' => data_path,
                                               'node-init-index-path' => index_path,
                                               'node-init-hostname' => hostname)
        end
    end
end
