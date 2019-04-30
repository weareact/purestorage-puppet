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

    def to_s?(value)
      value.inspect
    end
  end

  newproperty(:targets, :array_matching => :all) do
    desc "List of targets to include in protection group"

    # Pretty output for arrays.
    def should_to_s(value)
      value.inspect
    end

    def to_s?(value)
      value.inspect
    end
  end

  newproperty(:volumes, :array_matching => :all) do
    desc "List of volumes to include in protection group"

    # Pretty output for arrays.
    def should_to_s(value)
      value.inspect
    end

    def to_s?(value)
      value.inspect
    end
  end

  newparam(:snapshot_enabled) do
    desc "If snapshot schedule is enabled"
    newvalues(:true, :false)
  end

  newparam(:snapshot_frequency_unit) do
    desc "The unit of time snapshot frequency is defined as: minutes, hours, days"
    newvalues(:minutes, :hours, :days)
  end

  newparam(:snapshot_frequency_amount) do
    desc "How frequent snapshots are scheduled"
    newvalues(%r{\\d+})
  end

  newparam(:snapshot_at) do
    desc "Number of seconds after midnight that a daily snapshot is taken"
    newvalues(%r{\\d+})
  end

  newparam(:snapshot_retention_unit) do
    desc "The unit of time snapshot retention is defined as: minutes, hours, days"
    newvalues(:minutes, :hours, :days)
  end

  newparam(:snapshot_retention_amount) do
    desc "How long snapshots are kept for"
    newvalues(%r{\\d+})
  end

  newparam(:snapshot_per_day) do
    desc "How many snapshots are kept for the given number of days"
    newvalues(%r{\\d+})
  end

  newparam(:snapshot_for_days) do
    desc "How many days retained snapshots are kept for"
    newvalues(%r{\\d+})
  end

  newparam(:device_url) do
      desc "URL in the form of https://<user>:<passwd>@<FQ_Device_Name or IP>"
  end
end
