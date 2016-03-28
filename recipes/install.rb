ext = ::File.extname(package_url)
pkg_path = ::File.join(Chef::Config[:file_cache_path],
                       "couchbase-#{node['couchbase']['version']}#{ext}")
remote_file pkg_path do
    source package_url
    action :create_if_missing
end

case node['platform']
when 'debian', 'ubuntu'
    package 'libssl1.0.0'
    dpkg_package pkg_path do
        notifies :run, 'ruby_block[Wait for Couchbase to respond]', :immediately
    end
    wait_for_couchbase_to_respond 8091
else
    raise "Platform #{node['platform']} not supported"
end
