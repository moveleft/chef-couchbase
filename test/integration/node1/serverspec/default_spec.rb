require 'spec_helper'

describe port(8091) do
    it { should be_listening }
end

describe command('/opt/couchbase/bin/couchbase-cli server-list -c localhost:8091 ' \
                 '-u admin -p password') do
    its(:exit_status) { should eq 0 }
    its(:stdout) do
        should match(/node1.integration.monsenso.com:8091 healthy active$/)
    end
end
