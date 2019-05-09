node 'cloud-dev-405-a12-02.puretec.purestorage.com' {

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
