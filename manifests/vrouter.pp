#
# Class: contrail::vrouter
#
# == To setup contrail vrouter.
#
# [*vgw_enabled*]
#   Whether to enable simple gateway.
#   Simple gateway is used to provide external network connectivity without any
#   physical router, in test and development environments.
#
#   NOTE: This should not be used in production environment. As per contrail
#   documentation simple gateway is a restricted implementation of gateway which
#   can
#   be used for experimental purposes.
#
#   One important usecase of this is to test floating IP access in dev and test
#   environment where physical router would not be available.
#
# [*vgw_interface*]
#   The tap interface name for vgw. Default: vgw1
#
# [*vgw_subnets*]
#   Single subnet or  array of subnets in CIDR format (e.g. 10.0.0.0/24) for
#   which the
#   simple gateway to be added.
#
# [*vgw_dest_net*]
#   Single or an array of destination physical networks in CIDR format. In case
#   of
#   floating IP, it will be '0.0.0.0/0' which is default.
#
# [*vgw_vrf*]
#   Contrail fqname of the VRF on which the route to be added. e.g
#    default-domain:services:public:public is the fqname for the VRF
#        of public VN in services tenant
#     Default: default-domain:services:public:public - this will work for
#     floating IP.
#
# [*discovery_address*]
#    discovery server address, either IP address or resolvable dns name.
#
# [*api_address*]
#    Contrail API server address, either IP address or resolvable dns name.
#
# [*manage_repo*]
#  Whether to manage opencontrail (apt) repo or not.
#
# [*log_level*]
# Log severity levels. Possible values are SYS_EMERG, SYS_ALERT, SYS_CRIT,
# SYS_ERR, SYS_WARN, SYS_NOTICE, SYS_INFO and SYS_DEBUG. Default is SYS_INFO
#
# [*log_local*]
# Enable/Disable local file logging. Possible values are 0 (disable)
# and 1 (enable) (default is 1)
#
# [*log_file_size*]
# Maximum log file size before its rotated by log4cxx (default 10G 10737418240 )
#
# [*debug*]
#  Enable/disable debug logging.
#

class contrail::vrouter (
  $discovery_address,
  $keystone_admin_tenant,
  $keystone_admin_user,
  $keystone_admin_password,
  $api_address                = undef,
  $api_port                   = 8082,
  $package_names              = [ 'contrail-vrouter-agent','contrail-utils',
                                  'contrail-nova-driver','contrail-vrouter-dkms'],
  $package_ensure             = 'installed',
  $manage_repo                = false,
  $vrouter_interface          = 'vhost0',
  $vrouter_physical_interface = 'eth0',
  $vrouter_physical_interface_backup = undef,
  $interface_is_dhcp          = 'true',
  $vrouter_num_controllers    = 2,
  $vrouter_gw                 = undef,
  $metadata_proxy_secret      = 'set',
  $router_address             = undef,
  $network_mtu                = 1500,
  $headless_mode              = false,
  $hypervisor_type            = 'kvm',
  $vgw_enabled                = false,
  $vgw_interface              = 'vgw1',
  $vgw_subnets                = [],
  $vgw_dest_net               = '0.0.0.0/0',
  $vgw_vrf                    = 'default-domain:services:public:public',
  $lbaas                      = true,
  $log_level                  = 'SYS_INFO',
  $log_file_size              = 10737418240,
  $log_local                  = 1,
  $debug                      = false,
) {

  validate_bool($vgw_enabled)
  validate_re($vgw_interface,'vgw\d+')
  validate_string($vgw_vrf)
  validate_bool($lbaas)
  validate_bool($manage_repo)

  ##
  # restart contrail-vrouter-agent on changing vrouter configuration
  ##

  Package['contrail-vrouter-agent'] -> Contrail_vrouter_config<||>

  Contrail_vrouter_config<||> ~> Service['contrail-vrouter-agent']

  ##
  #  Setup repo if enabled.
  ##
  if $manage_repo {
    include contrail::repo

    ##
    # All package operations should follow apt::source
    ##

    Apt::Source<||> -> Package<||>
  }

  if has_interface_with($vrouter_physical_interface_backup) {
    $vrouter_physical_interface_orig = $vrouter_physical_interface_backup
  } elsif has_interface_with($vrouter_physical_interface) {
    $vrouter_physical_interface_orig = $vrouter_physical_interface
  }

  if has_interface_with($vrouter_interface) {
    $iface_for_vrouter_config = $vrouter_interface
  } elsif has_interface_with($vrouter_physical_interface) {
    $iface_for_vrouter_config = $vrouter_physical_interface
  } elsif has_interface_with($vrouter_physical_interface_backup) {
    $iface_for_vrouter_config = $vrouter_physical_interface_backup
  } else {
    fail("vrouter_physical_interface (${vrouter_physical_interface}) , backup interface (${vrouter_physical_interface_backup})  and vrouter_interface (${vrouter_interface}) dont exist")
  }

  ##
  # This code will support discovery_address and api_address is to be either dns name or ip address.
  # There are some places (in configuration) it need IP address, so resolve the dns name in case dns provided.
  ##
  if is_ip_address($discovery_address) {
    $discovery_ip = $discovery_address
  } else {
    $discovery_ip = dns_resolve($discovery_address)
  }

  if ! $api_address {
    $api_address_orig  = $discovery_address
  } else {
    $api_address_orig  = $api_address
  }

  $vrouter_ip  = inline_template("<%= scope.lookupvar('ipaddress_' + @iface_for_vrouter_config) %>")
  $vrouter_mac = inline_template("<%= scope.lookupvar('macaddress_' + @iface_for_vrouter_config) %>")
  $vrouter_netmask = inline_template("<%= scope.lookupvar('netmask_' + @iface_for_vrouter_config) %>")
  $vrouter_cidr = netmask2cidr($vrouter_netmask)


  ##
  # LBAAS Setup need haproxy installed on all compute nodes
  ##
  if $lbaas {
    ensure_packages(['haproxy'])
  }

  ##
  # Usually first IP of a network used to be the gateway ip address.
  # So making the first IP as default
  ##
  if $vrouter_gw {
    $vrouter_gw_orig = $vrouter_gw
  } else {
    $vrouter_gw_orig = nextip(inline_template("<%= scope.lookupvar('network_' + @iface_for_vrouter_config) %>"))
  }

  package { 'ufw':
    ensure  => absent,
  }
  
  ##
  # Due to a bug in vrouter on virtualbox, the following patch is required 
  # It can be removed once the issue has been fixed
  ##
  if ($::virtual == 'virtualbox') {
    $vrouter_patch='modprobe vrouter;'
  }
  else
  {
    $vrouter_patch=''
  }

  
  ensure_resource(package, "linux-headers-${::kernelrelease}")

  Package["linux-headers-${::kernelrelease}"] -> Package['contrail-vrouter-dkms']

  package {$package_names:
    ensure => $package_ensure,
  }

  ##
  # Setting up network interfaces
  ##
  exec { "/sbin/ifdown ${vrouter_physical_interface_orig}":
    unless => "/bin/grep 'iface ${vrouter_interface}' /etc/network/interfaces",
  } ->
  network_config { $vrouter_physical_interface_orig:
    ensure  => present,
    family  => 'inet',
    method  => 'manual',
    options => {
                'pre-down' => 'ifconfig $IFACE down',
                'pre-up'   => "ifconfig \$IFACE mtu ${network_mtu} up;${vrouter_patch} /usr/local/bin/if-vhost0 || true"
                },
    onboot  => true,
  } ->
  exec { "/sbin/ifup ${vrouter_physical_interface_orig}":
    unless => "/sbin/ifconfig | grep ^${vrouter_physical_interface_orig}",
  }

  if $interface_is_dhcp {
    network_config { $vrouter_interface:
      ensure  => present,
      family  => 'inet',
      method  => 'dhcp',
      onboot  => true,
      options => {
                  'pre-up' => "${vrouter_patch}/usr/local/bin/if-vhost0",
                  },
    } ->
    exec { "ifup_${vrouter_interface}":
      command => "/sbin/ifup ${vrouter_interface}",
      unless  => "/sbin/ifconfig | grep ^${vrouter_interface}",
      require => Package[$package_names],
    }
  }
  else {
    package {'ifupdown-extra':}
    network_config { $vrouter_interface:
      ensure  => present,
      family  => 'inet',
      method  => 'static',
      ipaddress => $vrouter_ip,
      netmask  => $vrouter_netmask,
      onboot  => true,
      options => {
                  'pre-up' => "${vrouter_patch}/usr/local/bin/if-vhost0",
                  },
    } ->
    network_route { 'default':
      ensure => present,
      gateway => $vrouter_gw_orig,
      interface => $vrouter_interface,
      netmask => '0.0.0.0',
      network => 'default',
      require => Package['ifupdown-extra']
    } ->
    exec { "ifup_${vrouter_interface}":
      command => "/sbin/ifup ${vrouter_interface}",
      unless  => "/sbin/ifconfig | grep ^${vrouter_interface}",
      require => Package[$package_names],
    }
  }

  # NOTE: below scripts are taken from contrail-vrouter-init package. It may
  # need to be packaged in future.
  # The package install those scritps under /opt/contrail/bin, for now, these
  # are added in /usr/local/bin
  ##
  file {'/usr/local/bin/vrouter-functions.sh':
    ensure => file,
    mode   => '0755',
    source => "puppet:///modules/${module_name}/vrouter-functions.sh",
  }

  file {'/usr/local/bin/if-vhost0':
    ensure => file,
    mode   => '0755',
    source => "puppet:///modules/${module_name}/if-vhost0",
  }

  ##
  # This was agent_param earlier, but upstream module has agent_param.tmpl need
  # to be confirmed
  ##
  file { '/etc/contrail/agent_param':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('contrail/agent_param.erb'),
    require => Package['contrail-vrouter-agent'],
    notify  => Service['contrail-vrouter-agent'],
  }

  ##
  # Upstream module has rpm_agent.conf - need to be confirmed
  ##

# NOTE UPSTREAM MODULE HAS VNC_API_LIB.INI file which is not added here. It
# seems that is for supervisor or something else.

  if $vrouter_ip {
    file { '/etc/contrail/agent.conf':
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      content => template('contrail/agent.conf.erb'),
      require => Package['contrail-vrouter-agent'],
      notify  => Service['contrail-vrouter-agent'],
    }

    file { '/etc/contrail/default_pmac':
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      content => $vrouter_mac,
      require => Package['contrail-vrouter-agent'],
      notify  => Service['contrail-vrouter-agent'],
    }

    contrail_vrouter_config {
      'DEFAULT/log_file':                           value => '/var/log/contrail/contrail-vrouter.log';
      'DEFAULT/log_level':                          value => $log_level;
      'DEFAULT/log_local':                          value => $log_local;
      'DEFAULT/log_file_size':                      value => $log_file_size;
      'DEFAULT/debug':                              value => bool2num($debug);
      'DEFAULT/headless_mode':                      value => $headless_mode;
      'DISCOVERY/server':                           value => $discovery_ip;
      'DISCOVERY/max_control_nodes':                value => $vrouter_num_controllers;
      'HYPERVISOR/type':                            value => $hypervisor_type;
      'NETWORKS/control_network_ip':                value => $vrouter_ip;
      'VIRTUAL-HOST-INTERFACE/name':                value => 'vhost0';
      'VIRTUAL-HOST-INTERFACE/ip':                  value => "${vrouter_ip}/${vrouter_cidr}";
      'VIRTUAL-HOST-INTERFACE/gateway':             value => $vrouter_gw_orig;
      'VIRTUAL-HOST-INTERFACE/physical_interface':  value => $vrouter_physical_interface_orig;
      'VIRTUAL-HOST-INTERFACE/compute_node_address':value => $vrouter_ip;
    }

    if $metadata_proxy_secret {
      contrail_vrouter_config { 'METADATA/metadata_proxy_secret':
        value => $metadata_proxy_secret,
      }
    }
  }

  file { '/etc/contrail/vrouter_nodemgr_param':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => "DISCOVERY=${discovery_ip}\n",
    require => Package['contrail-vrouter-agent'],
    notify  => Service['contrail-vrouter-agent'],
  }

  file { '/var/crash':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  sysctl::value { 'kernel.core_pattern': value => '/var/crash/core.%e.%p.%h.%t' }
  sysctl::value { 'net.ipv4.ip_forward': value => 1 }

  service { 'contrail-vrouter-agent':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  ##
  # Provision Contrail vrouter
  ##

  contrail_vrouter {$::hostname:
    ensure             => present,
    host_address       => $vrouter_ip,
    admin_tenant       => $keystone_admin_tenant,
    admin_user         => $keystone_admin_user,
    admin_password     => $keystone_admin_password,
    api_server_address => $api_address_orig,
    require            => Service['contrail-vrouter-agent'],
  }

  ##
  # Create vgw interface if enabled. This is only handle only one vgw interface,
  # which is enough usually. For multiple interfaces to create, contrail_vgw
  # should be called separately.
  ##
  if $vgw_enabled {
    contrail::vgw {$vgw_interface:
      subnet   => $vgw_subnets,
      vrf      => $vgw_vrf,
      dest_net => $vgw_dest_net,
      require  => Exec["ifup_${vrouter_interface}"],
    }
  }
}
