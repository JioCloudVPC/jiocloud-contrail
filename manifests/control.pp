#
# Class contrail::control
#
class contrail::control (
  $package_ensure  = present,
  $control_ip_list = [$::ipaddress],
  $config_ip       = $::ipaddress,
  $contrail_ip     = $::ipaddress,
  $api_virtual_ip  = '127.0.0.1',
  $discovery_virtual_ip = '127.0.0.1',
  $log_level       = 'SYS_INFO',
  $log_file_size   = 10737418240,
  $log_local       = 1,
  $enable_dns      = false,
  $dns_port        = '10000'
) {

  package {'contrail-control':
    ensure => $package_ensure,
  }

  if $enable_dns {
    package {'contrail-dns':
      ensure => $package_ensure,
    }
  ##
  # DNS configuration
  ##

    file { '/etc/contrail/dns.conf' :
      ensure  => present,
      content => template("${module_name}/dns.conf.erb"),
    }

  ##
  # Contrail Named Configuration
  ##

    file { '/etc/contrail/supervisord_control_files/contrail-named.ini' :
      ensure => present,
      source => "puppet:///modules/${module_name}/contrail-named.ini"
    }

    file { '/etc/contrail/dns/named.conf' :
      ensure  => present,
      content => template("${module_name}/contrail-named.conf.erb"),
    }

    service {'contrail-named':
      ensure    => running,
      enable    => true,
      subscribe => [ File['/etc/contrail/dns/named.conf'],
                File['/etc/contrail/supervisord_control_files/contrail-named.ini'] ],
      require   => Package['contrail-dns']
    }

    service {'contrail-dns':
      ensure    => running,
      enable    => true,
      subscribe => File['/etc/contrail/dns.conf'],
      require   => Package['contrail-dns']
    }
  }

  ##
  # control  configuration
  ##

  file { '/etc/contrail/contrail-control.conf' :
    ensure  => present,
    content => template("${module_name}/contrail-control.conf.erb"),
  }

  service {'contrail-control':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/contrail/contrail-control.conf'],
    require   => Package['contrail-control']
  }

}
