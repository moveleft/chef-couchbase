def service_listening?(port)
    cmd = Mixlib::ShellOut.new('netstat -lnt')
    cmd.run_command
    cmd.stdout.each_line.select { |l| l.split[3] =~ /#{port}/ }.any?
end

def endpoint_responding?(url)
    404 > Net::HTTP.get_response(URI.parse(url)).code.to_i
rescue EOFError, Errno::ECONNREFUSED
    return false
end

def package_url
    version = node['couchbase']['version']
    edition = node['couchbase']['edition']

    'http://packages.couchbase.com/releases/' \
    "#{version}/couchbase-server-#{edition}_#{version}-#{platform}#{arch}.#{ext}"
end

def platform
    case node['platform']
    when 'debian'
        'debian7_'
    when %w(centos redhat amazon scientific)
        'centos6.'
    when 'ubuntu'
        'ubuntu12.4_'
    end
end

def arch
    case node['platform']
    when %w(centos redhat amazon scientific)
        node['kernel']['machine'] == 'x86_64' ? 'x86_64' : 'x86'
    else
        node['kernel']['machine'] == 'x86_64' ? 'amd64' : 'x86'
    end
end

def ext
    case node['platform']
    when %w(centos redhat amazon scientific)
        'rpm'
    else
        'deb'
    end
end

def wait_for_couchbase_to_respond(port)
    timeout = 300
    ruby_block 'Wait for Couchbase to respond' do
        block do
            begin
                wait_for_endpoint(port, timeout)
            rescue Timeout::Error
                raise "Couchbase did not respond within #{timeout} seconds"
            end
        end
    end
end

def wait_for_endpoint(port, timeout)
    Timeout.timeout(timeout) do
        sleep 1 until endpoint_responding? "http://localhost:#{port}"
    end
end

def uri_from_path(path, opts = {})
    opts[:host] ||= 'localhost'
    opts[:port] ||= port
    URI.parse("http://#{opts[:host]}:#{opts[:port]}#{path}")
end

def get(path, opts = {})
    opts[:user] ||= admin_username
    opts[:password] ||= admin_password
    uri = uri_from_path(path, opts)
    Net::HTTP.start uri.host, uri.port do |http|
        r = Net::HTTP::Get.new uri.path
        r.basic_auth opts[:user], opts[:password]
        http.request r
    end
end

def get_json(path, opts = {})
    r = get(path, opts)
    if r.is_a? Net::HTTPSuccess
        Chef::JSONCompat.from_json r.body
    elsif !opts[:ignore_failure]
        r.error! unless r.is_a?(Net::HTTPNotFound)
    end
rescue Errno::ECONNREFUSED => e
    raise e unless opts[:ignore_failure]
end

def couchbase_cli(command, opts = {})
    cmd = couchbase_cmd(command, opts)
    opts.select { |x, _| ![:host, :port, :wait].include? x }
        .reduce(cmd) { |a, e| "#{a} --#{e[0]}=#{e[1]}" }
end

def couchbase_cmd(command, opts = {})
    opts[:port] ||= defined?(port) ? port : 8091
    opts[:host] ||= 'localhost'
    cmd = "#{node['couchbase']['install_path']}/bin/couchbase-cli #{command} " \
          "-c #{opts[:host]}:#{opts[:port]} "
    opts[:wait] ? "#{cmd} --wait" : cmd
end

def node_total_memory_mb
    node['memory']['total'][0..-3].to_i / 1024
end
