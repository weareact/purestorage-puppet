require 'puppet/util/network_device/pure'

class Puppet::Util::NetworkDevice::Pure::Facts
  attr_reader :facts

  def initialize

  end

  def retrieve
    @facts                    = {}
    @pure_storage             = {}
    @pure_storage['vendor_id'] = 'pure'

    Puppet.debug("Fetching facts from Pure Array")
    array_info = Purest::PhysicalArray.get
    Puppet.debug("Returned array info: #{array_info.inspect}")
    @pure_storage['array_name'] = array_info[:array_name]
    @pure_storage['version'] = array_info[:version]

    controller_info = Purest::PhysicalArray.get(controllers: true)
    Puppet.debug("Returned controller info: #{controller_info.inspect}")
    controller_hash             = convert_array_hash_to_hash_array(controller_info, :name)
    @pure_storage['controllers'] = controller_hash

    connection_info = Purest::Host.get(connect: true)
    Puppet.debug("Returned connection info: #{connection_info.inspect}")
    volume_info = Purest::Volume.get
    Puppet.debug("Returned volume info: #{volume_info.inspect}")

    connection_info.each do |ci|
      related_volume = volume_info.detect {|vol| vol[:name] == ci[:vol]}
      if related_volume
        ci[:volserial] = related_volume[:serial]
      end
    end

    connection_hash             = convert_array_hash_to_hash_array(connection_info, :name)
    @pure_storage['connections'] = connection_hash

    @facts['pure_storage'] = @pure_storage
    Puppet.debug("Got facts: #{@facts.inspect}")

    @facts
  end

  def convert_array_hash_to_hash_array(array, hash_key)
    result = {}
    array.each do |i|
      name    = i[hash_key].to_sym
      current = result[name] ||= []
      current << i.delete_if {|k, v| k == hash_key}
      result[name] = current
    end
    Puppet.debug("Converted hash: #{result.inspect}")

    result
  end
end
