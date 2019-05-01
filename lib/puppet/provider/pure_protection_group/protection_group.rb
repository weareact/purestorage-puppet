require 'net/http'
require 'puppet/provider/pure'
require 'puppet/util/network_device'
require 'puppet/util/network_device/pure/device'
require 'purest'

Puppet::Type.type(:pure_protection_group).provide(:protection_group, :parent => Puppet::Provider::Pure) do
  confine feature: :purest
  desc "Provider for PureStorage protection group."

  mk_resource_methods

  PERIOD = {days: 86400, hours: 3600, minutes: 60}

  def self.instances
    protection_groups = []

    # Multiple calls to API required as pure does not return all details in request.
    # Get a list of hosts from Pure array
    results = Purest::ProtectionGroup.get
    Puppet.debug("Got a protection group result set from Pure: #{results.inspect}")

    schedule_results = Purest::ProtectionGroup.get(schedule: true)
    Puppet.debug("Got a protection group schedule result set from Pure: #{schedule_results.inspect}")

    retention_results = Purest::ProtectionGroup.get(retention: true)
    Puppet.debug("Got a protection group retention result set from Pure: #{retention_results.inspect}")

    results.each do |protection_group|
      pg_hash = {
          name:    protection_group[:name],
          ensure:  :present,
          hosts:   protection_group[:hosts],
          targets: protection_group[:targets],
          volumes: protection_group[:volumes],
      }

      schedule = schedule_results.detect {|pg| pg[:name] == protection_group[:name]}

      if schedule
        pg_hash[:snapshot_enabled]          = schedule[:snap_enabled].to_s
        pg_hash[:snapshot_frequency_unit]   = calc_frequency_unit(schedule[:snap_frequency])
        pg_hash[:snapshot_frequency_amount] = calc_frequency_amount(pg_hash[:snapshot_frequency_unit], schedule[:snap_frequency])
        pg_hash[:snapshot_at]               = schedule[:snap_at] / 3600
      end

      retention = retention_results.detect {|pg| pg[:name] == protection_group[:name]}
      if retention
        pg_hash[:snapshot_retention_unit]   = calc_frequency_unit(retention[:all_for])
        pg_hash[:snapshot_retention_amount] = calc_frequency_amount(pg_hash[:snapshot_retention_unit], retention[:all_for])
        pg_hash[:snapshot_per_day]          = retention[:per_day]
        pg_hash[:snapshot_for_days]         = retention[:days]
      end

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

  def self.calc_frequency_unit(frequency)
    PERIOD.each do |period, amount|
      if frequency % amount == 0
        return period
      end
    end
  end

  def self.calc_frequency_amount(frequency, raw_value)
    return raw_value / PERIOD[frequency]
  end

  def calc_raw_amount(frequency, amount_value)
    return amount_value * PERIOD[frequency]
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

  def snapshot_enabled=(value)
    Puppet.debug("Updating Protection Group Snapshot Enabled")
    update_response = Purest::ProtectionGroup.update(name: @property_hash[:name], snap_enabled: resource[:snapshot_enabled])
    Puppet.debug("Updated Protection Group: #{update_response}")
    @property_hash[:snapshot_enabled] == value
  end

  def update_snapshot_frequency(unit, amount)
    Puppet.debug("Updating Protection Group Snapshot frequency")
    update_response = Purest::ProtectionGroup.update(name: @property_hash[:name], snap_frequency: calc_raw_amount(unit, amount))
    Puppet.debug("Updated Protection Group: #{update_response}")
  end

  def snapshot_frequency_unit=(value)
    update_snapshot_frequency(value, @property_hash[:snapshot_frequency_amount])
    @property_hash[:snapshot_frequency_unit] == value
  end

  def snapshot_frequency_amount=(value)
    update_snapshot_frequency(@property_hash[:snapshot_frequency_unit], value)
    @property_hash[:snapshot_frequency_amount] == value
  end

  def snapshot_at=(value)
    Puppet.debug("Updating Protection Group Snapshot Time")
    update_response = Purest::ProtectionGroup.update(name: @property_hash[:name], snap_at: resource[:snapshot_at] * 3600)
    Puppet.debug("Updated Protection Group: #{update_response}")
    @property_hash[:snapshot_at] == value

    if @property_hash[:snapshot_frequency_unit] != :days
      Puppet.warning("snapshot_at is only used when snapshot_frequency_unit is days, this change will have no effect.")
    end
  end

  def update_retention_frequency(unit, amount)
    Puppet.debug("Updating Protection Group retention frequency")
    update_response = Purest::ProtectionGroup.update(name: @property_hash[:name], all_for: calc_raw_amount(unit, amount))
    Puppet.debug("Updated Protection Group: #{update_response}")
  end

  def retention_frequency_unit=(value)
    update_retention_frequency(value, @property_hash[:snapshot_retention_amount])
    @property_hash[:snapshot_retention_unit] == value
  end

  def retention_frequency_amount=(value)
    update_retention_frequency(@property_hash[:snapshot_retention_unit], value)
    @property_hash[:snapshot_retention_amount] == value
  end

  def snapshot_per_day=(value)
    Puppet.debug("Updating Protection Group Snapshot retention per day")
    update_response = Purest::ProtectionGroup.update(name: @property_hash[:name], per_day: resource[:snapshot_per_day])
    Puppet.debug("Updated Protection Group: #{update_response}")
    @property_hash[:snapshot_per_day] == value
  end

  def snapshot_for_days=(value)
    Puppet.debug("Updating Protection Group Snapshot retention number of days")
    update_response = Purest::ProtectionGroup.update(name: @property_hash[:name], days: resource[:snapshot_for_days])
    Puppet.debug("Updated Protection Group: #{update_response}")
    @property_hash[:snapshot_for_days] == value
  end

end
