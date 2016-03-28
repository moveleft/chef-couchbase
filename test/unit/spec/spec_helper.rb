require 'rspec/expectations'
require 'chefspec'
require 'chefspec/berkshelf'
require 'chef-vault'

module Mixlib
    module Shellout
    end
end

at_exit { ChefSpec::Coverage.report! }
