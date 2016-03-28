# Encoding: utf-8
require 'bundler/setup'

namespace :style do
    require 'rubocop/rake_task'
    desc 'Run Ruby style checks'
    RuboCop::RakeTask.new(:ruby)

    require 'foodcritic'
    desc 'Run Chef style checks'
    FoodCritic::Rake::LintTask.new(:chef) do |t|
    end
end

desc 'Run all style checks'
task style: ['style:chef', 'style:ruby']

require 'rspec/core/rake_task'
desc 'Run ChefSpec unit tests'
RSpec::Core::RakeTask.new(:spec) do |t, _args|
    t.rspec_opts = 'test/unit'
end

require 'kitchen'
desc 'run integration tests'
task :integration do
    ec = system('kitchen destroy')
    raise "kitchen destroy failed, exit code: #{ec}" unless ec

    ec = system('kitchen converge node1-debian-8')
    raise "Converging node1-debian-8 failed, exit code: #{ec}" unless ec
    ec = system('kitchen verify node1-debian-8')
    raise "Verifying node1-debian-8 failed, exit code: #{ec}" unless ec

    ec = system('kitchen converge node2-debian-8')
    raise "Converging node2-debian-8 failed, exit code: #{ec}" unless ec
    ec = system('kitchen verify node2-debian-8')
    raise "Verifying node2-debian-8 failed, exit code: #{ec}" unless ec

    system('kitchen destroy')
end

task default: %w(style spec integration)
