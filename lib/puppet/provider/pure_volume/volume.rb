require 'net/http'
require 'puppet/provider/pure'
require 'puppet/util/network_device'
require 'puppet/util/network_device/pure/device'
require 'purest'

Puppet::Type.type(:pure_volume).provide(:volume, :parent => Puppet::Provider::Pure) do
  confine feature: :purest
  desc "Provider for type PureStorage volume."

  mk_resource_methods

  def self.instances
    volumes = []

    # Get a list of volumes from Pure array
    results = Purest::Volume.get
    Puppet.debug("Got a volume result set from Pure: #{results.inspect}")

    results.each do |volume|
      volume_hash = {
        :name   => volume[:name],
        :ensure => :present
      }

      # Need to convert from bytes to biggest possible unit
      vol_size_bytes = volume['size']
      vol_size_mb = vol_size_bytes / 1024 / 1024
      if vol_size_mb % 1024 == 0
        vol_size_gb = vol_size_mb / 1024
        if vol_size_gb % 1024 == 0
          vol_size_tb = vol_size_gb / 1024
          vol_size = vol_size_tb.to_s + "T"
        else
          vol_size = vol_size_gb.to_s + "G"
        end
      else
        vol_size = vol_size_mb.to_s + "M"
      end
      volume_hash[:size] = vol_size

      Puppet.debug("Volume resource looks like: #{volume_hash}")

      # Add volume to list of volumes
      volumes << new(volume_hash)
    end

    volumes
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def create
    Puppet.debug("Creating volume #{resource[:name]} ")
    create_response = Purest::Volume.create(name: resource[:name], size: resource[:size])
    Puppet.debug("Created Volume: #{create_response}")
  end

  def destroy
    Puppet.debug("Deleting volume #{resource[:name]}")
    delete_response = Purest::Volume.delete(name: resource[:name])
    Puppet.debug("Deleted Volume: #{delete_response}")
    @property_hash.clear
  end

  def exists?
    Puppet.debug("Checking existence...")
    @property_hash[:ensure] == :present
  end

  # Pure API does not permit updating all these parameters at once, individual calls must be made.
  def name=(value)
    Puppet.debug("Updating Volume Name")
    update_response = Purest::Volume.update(name: @property_hash[:name], new_name: resource[:name])
    Puppet.debug("Updated Volume: #{update_response}")
    @property_hash[:name] == value
  end

  # size setter
  def size=(value)
    Puppet.debug("Updating Volume Size")
    update_response = Purest::Volume.update(name: @property_hash[:name], size: resource[:size])
    Puppet.debug("Updated Volume: #{update_response}")
    @property_hash[:size] == value
  end
end

