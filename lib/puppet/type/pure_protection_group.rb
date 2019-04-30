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

  newparam(:device_url) do
      desc "URL in the form of https://<user>:<passwd>@<FQ_Device_Name or IP>"
  end
end
