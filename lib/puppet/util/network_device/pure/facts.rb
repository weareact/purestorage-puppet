require 'puppet/util/network_device/pure'
require 'purest'

class Puppet::Util::NetworkDevice::Pure::Facts
  attr_reader :transport, :facts

  def initialize

  end

  def retrieve
    @facts                    = {}
    @pure_storage             = {}
    @pure_storage[:vendor_id] = 'pure'

    Puppet.debug("Fetching facts from Pure Array")
    array_info = Purest::PhysicalArray.get
    Puppet.debug("Returned array info: #{array_info.inspect}")
    @pure_storage[:array_name] = array_info[:array_name]
    @pure_storage[:version]    = array_info[:version]

    controller_info = Purest::PhysicalArray.get(controllers: true)
    Puppet.debug("Returned controller info: #{controller_info.inspect}")
    controller_hash             = controller_info.map {|controller| [controller[:name], controller.delete_if {|k, v| k == :name}]}.to_h
    @pure_storage[:controllers] = controller_hash

    connection_info = Purest::Host.get(connect: true)
    Puppet.debug("Returned connection info: #{connection_info.inspect}")
    connection_hash             = connection_info.map {|connection| [connection[:name], connection.delete_if {|k, v| k == :name}]}.to_h
    @pure_storage[:connections] = connection_hash

    Puppet.debug("Got facts: #{@facts.inspect}")

    @facts[:pure_storage] = @pure_storage

    @facts
  end
end
