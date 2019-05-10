node 'cloud-dev-405-a12-02.puretec.purestorage.com' {

  pure_host { 'pure_storage_host':
    ensure  => 'present',
    name    => 'test-host',
    iqnlist => 'iqn.1994-04.jp.co.hitachi:rsd.d9s.t.10103.0e02a',
  }
}
