require 'purest'

Facter.add(:pure_storage) do
  @facts              = {}
  @facts['vendor_id'] = 'pure'

  Puppet.debug("Fetching facts from Pure Array")
  array_info = Purest::PhysicalArray.get
  Puppet.debug("Returned array info: #{array_info.inspect}")
  @facts['array_name'] = array_info[:array_name]
  @facts['version']    = array_info[:version]

  controller_info = Purest::PhysicalArray.get(controllers: true)
  Puppet.debug("Returned controller info: #{controller_info.inspect}")
  @facts['controllers'] = controller_info

  connection_info = Purest::Host.get(connect: true)
  Puppet.debug("Returned connection info: #{connection_info.inspect}")
  @facts['connections'] = connection_info
  Puppet.debug("Got facts: #{@facts.inspect}")

  @facts
end




