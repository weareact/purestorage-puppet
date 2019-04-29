require 'net/http'
require 'puppet/provider/pure'
require 'puppet/util/network_device'
require 'puppet/util/network_device/pure/device'

Puppet::Type.type(:pure_host).provide(:host, :parent => Puppet::Provider::Pure) do
  confine feature: :purest
  desc "Provider for PureStorage host."

  mk_resource_methods

  def self.instances
    hosts = []

    # Get a list of hosts from Pure array
    results = Purest::Host.get
    Puppet.debug("Got a host result set from Pure: #{results.inspect}")

    results.each do |host|
      host_hash = {
          name:    host[:name],
          ensure:  :present,
          iqnlist: host[:iqn],
          wwnlist: host[:wwn]
      }

      Puppet.debug("Host resource looks like: #{host_hash.inspect}")
      hosts << new(host_hash)
    end

    hosts
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def create
    Puppet.debug("<<<<<<<<<< Inside hostconfig create for host #{resource[:name]}")
    create_response = Purest::Host.create(name: resource[:name], iqnlist: resource[:iqnlist], wwnlist: resource[:wwnlist])
    Puppet.debug("Created Host: #{create_response}")
  end

  def destroy
    Puppet.debug("Triggering destroy for #{resource[:name]}")
    delete_response = Purest::Host.delete(name: resource[:name])
    Puppet.debug("Deleted Host: #{delete_response}")
    @property_hash.clear
  end

  def exists?
    Puppet.debug("Checking existence...")
    @property_hash[:ensure] == :present
  end

  # Pure API does not permit updating all these parameters at once, individual calls must be made.
  def name=(value)
    Puppet.debug("Updating Host Name")
    update_response = Purest::Host.update(name: resource[:name])
    Puppet.debug("Updated Host: #{update_response}")
    @property_hash[:name] == value
  end

  def iqnlist=(value)
    Puppet.debug("Updating Host IQN List")
    update_response = Purest::Host.update(iqnlist: resource[:iqnlist])
    Puppet.debug("Updated Host: #{update_response}")
    @property_hash[:iqnlist] == value
  end

  def wwnlist=(value)
    Puppet.debug("Updating Host WWN List")
    update_response = Purest::Host.update(wwnlist: resource[:wwnlist])
    Puppet.debug("Updated Host: #{update_response}")
    @property_hash[:wwnlist] == value
  end

end
