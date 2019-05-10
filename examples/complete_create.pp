#Example of Puppet Device
node 'cloud-dev-405-a12-02.puretec.purestorage.com' { #--> This is Device name
  pure_volume { 'pure_storage_volume':
    #ensure either 'present' or 'absent'
    ensure => 'present',
    name   => 'test_device_volume',
    size   => '2G',
  }
  pure_host { 'pure_storage_host':
    ensure       => 'present',
    host_name    => 'test-device-host',
    host_iqnlist => ['iqn.1994-04.jp.co.pure:rsd.d9s.t.10103.0e03f', 'iqn.1994-04.jp.co.pure:rsd.d9s.t.10103.0e03g'],
  }
  pure_connection { 'pure_storage_connection':
    ensure      => 'present',
    host_name   => 'test-device-host',
    volume_name => 'test_device_volume',
  }

  pure_protection_group { 'pure_protection_group':
    name                      => 'test_protection_group',
    volumes                   => ['test_device_volume'],
    snapshot_enabled          => 'true',
    snapshot_frequency_unit   => 'days',
    snapshot_frequency_amount => 1,
    snapshot_at               => 3,
    snapshot_retention_unit   => 'days',
    snapshot_retention_amount => 5,
    snapshot_per_day          => 1,
    snapshot_for_days         => 5,
  }

}
#Example of Puppet Agent
node 'puppet-agent.puretec.purestorage.com' { #--> This is Agent vm name
  #Note : device_url is MANDATORY here.
  $device_url = 'https://pureuser:******@cloud-dev-405-a12-02.puretec.purestorage.com'

  pure_volume { 'pure_storage_volume':
    #ensure either 'present' or 'absent'
    ensure      => 'present',
    volume_name => 'test_agent_volume',
    volume_size => '2G',
    device_url  => $device_url,
  }
  pure_host { 'pure_storage_host':
    ensure       => 'present',
    host_name    => 'test-agent-host',
    host_iqnlist => ['iqn.1994-04.jp.co.pure:rsd.d9s.t.10103.0e03h', 'iqn.1994-04.jp.co.pure:rsd.d9s.t.10103.0e0i'],
    device_url   => $device_url,
  }
  pure_connection { 'pure_storage_connection':
    ensure      => 'present',
    host_name   => 'test-agent-host',
    volume_name => 'test_agent_volume',
    device_url  => $device_url,
  }

  pure_protection_group { 'pure_protection_group':
    name                      => 'test_protection_group',
    volumes                   => ['test_device_volume'],
    snapshot_enabled          => 'true',
    snapshot_frequency_unit   => 'days',
    snapshot_frequency_amount => 1,
    snapshot_at               => 3,
    snapshot_retention_unit   => 'days',
    snapshot_retention_amount => 5,
    snapshot_per_day          => 1,
    snapshot_for_days         => 5,
    device_url => $device_url,
  }
}
#Example of Puppet Apply
node 'puppet.puretec.purestorage.com' { #--> This is master vm name
  #Note: device_url is MANDATORY here.
  $device_url = 'https://pureuser:******@cloud-dev-405-a12-02.puretec.purestorage.com'

  pure_volume { 'pure_storage_volume':
    #ensure either 'present' or 'absent'
    ensure     => 'present',
    name       => 'test_apply_volume',
    size       => '2G',
    device_url => $device_url,
  }
  pure_host { 'pure_storage_host':
    ensure     => 'present',
    name       => 'test-apply-host',
    iqnlist    => ['iqn.1994-04.jp.co.pure:rsd.d9s.t.10103.0e03j', 'iqn.1994-04.jp.co.pure:rsd.d9s.t.10103.0e03k'],
    device_url => $device_url,
  }
  pure_connection { 'pure_storage_connection':
    ensure      => 'present',
    host_name   => 'test-apply-host',
    volume_name => 'test_apply_volume',
    device_url  => $device_url,
  }

  pure_protection_group { 'pure_protection_group':
    name                      => 'test_protection_group',
    volumes                   => ['test_device_volume'],
    snapshot_enabled          => 'true',
    snapshot_frequency_unit   => 'days',
    snapshot_frequency_amount => 1,
    snapshot_at               => 3,
    snapshot_retention_unit   => 'days',
    snapshot_retention_amount => 5,
    snapshot_per_day          => 1,
    snapshot_for_days         => 5,
    device_url => $device_url,
  }
}
