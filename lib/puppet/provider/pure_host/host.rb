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

  def flush
    Puppet.debug("Flushing resource #{resource[:name]}: #{resource.inspect}")

    Puppet.debug("Updating host resource")
    Purest::Host.update(name: resource[:name], iqnlist: resource[:iqnlist], wwnlist: resource[:wwnlist])
  end

  def create
    Puppet.debug("<<<<<<<<<< Inside hostconfig create for host #{resource[:name]}")
    Purest::Host.create(name: resource[:name], iqnlist: resource[:iqnlist], wwnlist: resource[:wwnlist])
  end

  def update
    Puppet.debug("<<<<<<<<<< Inside hostconfig update for host #{resource[:name]}")
  end

  def destroy
    Puppet.debug("Triggering destroy for #{resource[:name]}")
    Purest::Host.delete(name: resource[:name])
  end

  def exists?
    Puppet.debug("Checking existence...")
    @property_hash[:ensure] == :present
  end

end
