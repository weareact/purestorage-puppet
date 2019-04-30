require 'net/http'
require 'puppet/provider/pure'
require 'puppet/util/network_device'
require 'puppet/util/network_device/pure/device'
require 'purest'

Puppet::Type.type(:pure_protection_group).provide(:protection_group, :parent => Puppet::Provider::Pure) do
  confine feature: :purest
  desc "Provider for PureStorage protection group."

  mk_resource_methods

  def self.instances
    protection_groups = []

    # Get a list of hosts from Pure array
    results = Purest::ProtectionGroup.get
    Puppet.debug("Got a protection group result set from Pure: #{results.inspect}")

    results.each do |protection_group|
      pg_hash = {
          name:    protection_group[:name],
          ensure:  :present,
          iqnlist: protection_group[:iqn],
          wwnlist: protection_group[:wwn]
      }

      Puppet.debug("Protection Group resource looks like: #{pg_hash.inspect}")
      protection_groups << new(pg_hash)
    end

    protection_groups
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def create
    Puppet.debug("Creating protection group #{resource[:name]}")
    create_response = Purest::ProtectionGroup.create(name: resource[:name], hostlist: resource[:hosts], targetlist: resource[:targets], vollist: resource[:volumes])
    Puppet.debug("Created Protection Group: #{create_response}")
  end

  def destroy
    Puppet.debug("Deleting protection group #{resource[:name]}")
    delete_response = Purest::ProtectionGroup.delete(name: resource[:name])
    Puppet.debug("Deleted Protection Group: #{delete_response}")
    @property_hash.clear
  end

  def exists?
    Puppet.debug("Checking existence...")
    @property_hash[:ensure] == :present
  end

  # Pure API does not permit updating all these parameters at once, individual calls must be made.
  def name=(value)
    Puppet.debug("Updating Protection Group Name")
    update_response = Purest::ProtectionGroup.update(name: @property_hash[:name], new_name: resource[:name])
    Puppet.debug("Updated Protection Group: #{update_response}")
    @property_hash[:name] == value
  end

  def hosts=(value)
    Puppet.debug("Updating Protection Group Host List")
    update_response = Purest::ProtectionGroup.update(name: @property_hash[:name], hostlist: resource[:hosts])
    Puppet.debug("Updated Protection Group: #{update_response}")
    @property_hash[:hosts] == value
  end

  def targets=(value)
    Puppet.debug("Updating Protection Group Target List")
    update_response = Purest::ProtectionGroup.update(name: @property_hash[:name], targetlist: resource[:targets])
    Puppet.debug("Updated Protection Group: #{update_response}")
    @property_hash[:targets] == value
  end

  def volumes=(value)
    Puppet.debug("Updating Protection Group Volume List")
    update_response = Purest::ProtectionGroup.update(name: @property_hash[:name], vollist: resource[:volumes])
    Puppet.debug("Updated Protection Group: #{update_response}")
    @property_hash[:volumes] == value
  end

end
