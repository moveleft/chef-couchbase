require_relative 'spec_helper'

describe 'chef-couchbase::install' do
    cached(:chef_run) do
        r = ChefSpec::SoloRunner.new(platform: 'debian', version: '8.1')
        r.node.set['couchbase']['version'] = '6.4.1'
        r.converge(described_recipe)
    end
    let(:pkg_path) do
        ::File.join(Chef::Config[:file_cache_path], 'couchbase-6.4.1.deb')
    end

    it 'must install libssl1.0.0' do
        expect(chef_run).to install_package('libssl1.0.0')
    end

    it 'must download the Couchbase package' do
        expect(chef_run).to create_remote_file_if_missing(pkg_path)
    end

    it 'must install Couchbase' do
        expect(chef_run).to install_dpkg_package(pkg_path)
    end

    it 'must wait for Couchbase to respond' do
        expect(chef_run).to run_ruby_block('Wait for Couchbase to respond')
    end
end
