require_relative 'spec_helper'

describe 'chef-couchbase::node' do
    let(:chef_run) do
        r = ChefSpec::SoloRunner.new(platform: 'debian', version: '8.1')
        r.node.set['couchbase']['cluster_search_query'] = 'name:void'
        r.converge(described_recipe)
    end
    before do
        allow(ChefVault::Item).to receive(:vault?)
            .with('couchbase', 'couchbase').and_return(true)
        allow(ChefVault::Item).to receive(:load)
            .with('couchbase', 'couchbase')
            .and_return('admin_username' => 'admin', 'admin_password' => 'password')
        allow_any_instance_of(Chef::Recipe).to receive(:include_recipe)
            .with('chef-couchbase::install').and_return true
        allow_any_instance_of(Chef::Recipe).to receive(:include_recipe)
            .with('chef-vault').and_return true
        stub_search(:node, 'name:void')
            .and_return([])
    end

    it 'must create the log_dir directory' do
        expect(chef_run).to create_directory('/var/log/couchbase')
            .with(recursive: true, owner: 'couchbase', group: 'couchbase',
                  mode: 0755)
    end

    it 'must create the data_path directory' do
        expect(chef_run).to create_directory('/var/lib/couchbase/data')
            .with(recursive: true, owner: 'couchbase', group: 'couchbase',
                  mode: 0755)
    end

    it 'must create the index_path directory' do
        expect(chef_run).to create_directory('/var/lib/couchbase/index')
            .with(recursive: true, owner: 'couchbase', group: 'couchbase',
                  mode: 0755)
    end

    it 'must initialize the node' do
        expect(chef_run).to modify_couchbase_node('self')
    end

    context 'when no couchbase cluster exists' do
        it 'must initialize a new cluster' do
            expect(chef_run).to init_couchbase_cluster('Initialize cluster')
        end
    end

    context 'when a Couchbase cluster exists' do
        before do
            stub_search(:node, 'name:void')
                .and_return([{ 'couchbase' => { 'port' => 891 }, 'fqdn' => 'x.y' }])
        end

        it 'must join the existing cluster' do
            expect(chef_run).to join_couchbase_cluster('Join cluster')
                .with(cluster_server: 'x.y', cluster_server_port: 891)
        end
    end
end
