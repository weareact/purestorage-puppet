# Define the connected volume
define purefa::connected_volume (
  String $hostname,
  String $volumename,
  String $volumeserial,
  Integer $lun
) {

  $_wwid = downcase("3624a9370${volumeserial}")

  if $volumename =~ /_data$/ {
    $_trimmed_name = regsubst($volumename, "_data", "")
    $_mount_location = "/data/${_trimmed_name}"
    $_owner = 'oracle'
    $_group = 'oinstall'
  }
  elsif $volumename =~ /_archive$/ {
    $_trimmed_name = regsubst($volumename, "_archive", "")
    $_mount_location = "/archivelogs/${_trimmed_name}"
    $_owner = 'oracle'
    $_group = 'oinstall'
  }
  elsif $volumename =~ /_software$/ {
    $_mount_location = '/software/oracle'
    $_owner = 'oracle'
    $_group = 'oinstall'
  }
  elsif $volumename =~ /shared_staging$/ {
    $_mount_location = '/stage'
    $_owner = 'oracle'
    $_group = 'oinstall'
  }
  else {
    $_mount_location = "/mnt/${volumename}"
    $_owner = 'root'
    $_group = 'root'
  }

  exec { "mkdir-${_mount_location}":
    creates => $_mount_location,
    command => "mkdir -p ${_mount_location} && chown ${_owner}:${_group} ${_mount_location}",
    path    => $::path
  } -> file { $_mount_location: }

  multipath::path { "${_wwid}":
    ensure => 'present',
    devalias => $volumename,
    notify => Service['multipath']
  }

  exec { "mkfs-${volumename}":
    command => "/usr/sbin/mkfs.xfs /dev/mapper/${volumename}",
    unless  => "/usr/sbin/blkid -t TYPE=xfs /dev/mapper/${volumename}",
    require => [File["${_mount_location}"], Multipath::Path["${_wwid}"]],
  }

  mount { $_mount_location:
    ensure  => 'mounted',
    atboot  => true,
    device  => "/dev/mapper/${volumename}",
    fstype  => 'xfs',
    options => 'defaults,discard,_netdev',
    require => Exec["mkfs-${volumename}"],
    notify => Exec["owndir-${_mount_location}"]
  }

  exec { "owndir-${_mount_location}":
    command => "chown -R ${_owner}:${_group} ${_mount_location}",
    path    => $::path,
    refreshonly => true
  }

}
