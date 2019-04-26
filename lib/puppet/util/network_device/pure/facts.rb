require 'puppet/util/network_device/pure'
require 'puppet/purestorage_api'
require 'purest'

class Puppet::Util::NetworkDevice::Pure::Facts
  attr_reader :transport, :facts

  def initialize

  end

  def retrieve
    Puppet.debug("Fetching facts from Pure Array")
    array_info = Purest::PhysicalArray.get
    Puppet.debug("Returned array info: #{array_info.inspect}")

    controller_info = Purest::PhysicalArray.get(controllers: true)
    Puppet.debug("Returned controller info: #{controller_info.inspect}")

    @facts = {}
    @facts['array_name']  = array_info[:array_name]
    @facts['controllers'] = controller_info
    @facts['vendor_id']   = 'pure'
    @facts['version']     = array_info[:version]
    Puppet.debug("Got facts: #{@facts.inspect}")
    @facts
  end
end
