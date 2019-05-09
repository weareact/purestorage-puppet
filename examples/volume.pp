node 'cloud-dev-405-a12-02.puretec.purestorage.com' {

  pure_volume { 'pure_storage_volume':
    ensure => 'present',
    name   => 'test_02',
    size   => '4.0G',
  }
}
