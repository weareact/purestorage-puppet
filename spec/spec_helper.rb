RSpec.configure do |c|
  c.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles        = true
    mocks.verify_doubled_constant_names = true
  end
end
require 'puppetlabs_spec_helper/module_spec_helper'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  if ENV['PUPPET_DEBUG']
    c.before(:each) do
      Puppet::Util::Log.level = :debug
      Puppet::Util::Log.newdestination(:console)
    end
  end

  c.before(:each) do
    allow_any_instance_of(Purest::Rest).to receive(:establish_connection) {}
    allow_any_instance_of(Purest::Rest).to receive(:authenticated?).and_return(true)
  end

  c.color                = true
  c.trusted_server_facts = true
end

