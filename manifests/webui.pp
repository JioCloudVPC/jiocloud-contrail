#
# Class: contrail::webui
#   Provide web based ui
#
# == Parameters
#
#
#
class contrail::webui (
  $package_ensure     = 'present',
  $api_virtual_ip     = '127.0.0.1',
  $discovery_virtual_ip = '127.0.0.1',
  $contrail_ip        = $::ipaddress,
  $webui_ip           = $::ipaddress,
  $config_ip          = $::ipaddress,
  $neutron_port       = 9696,
  $neutron_protocol   = http,
  $glance_address     = $::ipaddress,
  $glance_port        = 9292,
  $glance_protocol    = http,

  $nova_address       = $::ipaddress,
  $nova_port          = 8774,
  $nova_protocol      = http,

  $keystone_address   = $::ipaddress,
  $keystone_port      = 5000,
  $keystone_protocol  = http,

  $cinder_address     = $::ipaddress,
  $cinder_port        = 8776,
  $cinder_protocol    = http,

  $analytics_data_ttl = 48, ## Number of hours to keep the data
  $cassandra_ip_list  = [$::ipaddress],
  $redis_ip           = $::ipaddress,
  $cassandra_port     = 9160,
  $glance_address     = $::ipaddress,
  $nova_address       = $::ipaddress,
  $keystone_address   = $::ipaddress,
  $cinder_address     = $::ipaddress,
  $collector_ip       = $::ipaddress,
) {

  package {['contrail-web-core','contrail-web-controller']:
    ensure => $package_ensure,
  }

  ##
  # Contrail webui need a specific version of >= (0.8-contrail1) nodejs.
  # So pinning it on contrail node.
  ##
  apt::pin {'nodejs_for_contrail_webui':
    priority => 1001,
    packages => 'nodejs',
    version  => '*contrail1'
  }

  Apt::Pin<||> -> Package<||>

  file { '/etc/contrail/config.global.js':
    ensure  => present,
    content => template("${module_name}/config.global.js.erb"),
    require => [ Package['contrail-web-controller'],
                Package['contrail-web-core'] ],
  }

  file { '/etc/init.d/contrail-webui-jobserver':
    ensure  => link,
    target  => '/lib/init/upstart-job',
    require => [ Package['contrail-web-controller'],
                Package['contrail-web-core'] ],
  }

  service {'contrail-webui-jobserver':
    ensure    => running,
    require   => [ Package['contrail-web-controller'],
                Package['contrail-web-core'] ],
    subscribe => File['/etc/contrail/config.global.js'],
  }

  file { '/etc/init.d/contrail-webui-webserver':
    ensure  => link,
    target  => '/lib/init/upstart-job',
    require => [ Package['contrail-web-controller'],
                Package['contrail-web-core'] ],
  }

  service {'contrail-webui-webserver':
    ensure    => running,
    require   => [ Package['contrail-web-controller'],
                Package['contrail-web-core'] ],
    subscribe => File['/etc/contrail/config.global.js'],
  }


}
