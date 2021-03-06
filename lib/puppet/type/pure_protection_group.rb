Puppet::Type.newtype(:pure_protection_group) do
  @doc = "It does CRUD operations for protection groups on a Pure Storage flash array."
  
  apply_to_all
  ensurable
  
  newparam(:name) do
    desc "The name of the protection group."
    isnamevar
  end
  
  newproperty(:hosts, :array_matching => :all) do
    desc "List of hosts to include in protection group"

    # Pretty output for arrays.
    def should_to_s(value)
      value.inspect
    end

    def is_to_s(value)
      value.inspect
    end

    def insync?(is)
      is.sort == should.sort
    end

  end

  newproperty(:targets, :array_matching => :all) do
    desc "List of targets to include in protection group"

    # Pretty output for arrays.
    def should_to_s(value)
      value.inspect
    end

    def is_to_s(value)
      value.inspect
    end

    def insync?(is)
      is.sort == should.sort
    end

  end

  newproperty(:volumes, :array_matching => :all) do
    desc "List of volumes to include in protection group"

    # Pretty output for arrays.
    def should_to_s(value)
      value.inspect
    end

    def is_to_s(value)
      value.inspect
    end

    def insync?(is)
      is.sort == should.sort
    end

  end

  newproperty(:snapshot_enabled) do
    desc "If snapshot schedule is enabled"
    newvalues(:true, :false)
  end

  newproperty(:snapshot_frequency_unit) do
    desc "The unit of time snapshot frequency is defined as: minutes, hours, days"
    newvalues(:minutes, :hours, :days)
  end

  newproperty(:snapshot_frequency_amount) do
    desc "How frequent snapshots are scheduled"
    newvalues(%r{\d+})
  end

  newproperty(:snapshot_at) do
    desc "Number of seconds after midnight that a daily snapshot is taken"
    newvalues(%r{\d+})
  end

  newproperty(:snapshot_retention_unit) do
    desc "The unit of time snapshot retention is defined as: minutes, hours, days"
    newvalues(:minutes, :hours, :days)
  end

  newproperty(:snapshot_retention_amount) do
    desc "How long snapshots are kept for"
    newvalues(%r{\d+})
  end

  newproperty(:snapshot_per_day) do
    desc "How many snapshots are kept for the given number of days"
    newvalues(%r{\d+})
  end

  newproperty(:snapshot_for_days) do
    desc "How many days retained snapshots are kept for"
    newvalues(%r{\d+})
  end

  newparam(:device_url) do
      desc "URL in the form of https://<user>:<passwd>@<FQ_Device_Name or IP>"
  end

  # Require pure_host and pure_volume resources
  autorequire(:pure_host) do
    self[:hosts]
  end

  autorequire(:pure_volume) do
    self[:volumes]
  end
end
