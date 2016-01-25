# == Class: contrail
#
# This class to setup opencontrail.
#
# === Parameters
#
# [*control_ip_list*]
#   An array of contrail control node IP list
#
# [*keystone_address*]
#  Keystone server
#
# [*keystone_admin_token*]
#  Keystone admin token
#
# [*keystone_admin_password*]
#  Keystone admin password
#
# [*keystone_auth_password*]
#  Keystone service user password
#
# [*keystone_admin_port*]
#  Keystone admin port, default to 35357
#
# [*keystone_protocol*]
#  Keystone protocol, default to http
#
# [*keystone_port*]
# Keystone port - defaults to 5000
# [*haproxy_enabled*]
#  Whether to enable local haproxy or not.
# Note: in case local haproxy enabled, all contrail servers will have one
# instance of haproxy running, which will be load balancing the requests to all
# other contrail nodes.
#  There is a problem with this method, in case haproxy is down on one node, any
#  clients connect to this node will cause issues. This must be handled using
#  pacemaker or any other cluster management tools to effectively mange it.
#  Other option is to move the load balancing to external load balancer cluster
#
# [*neutron_ip*]
#  Neutron ip address
# Note: original contrail code make neutron IP as localhost if haproxy is
# enabled. They are configuring haproxy on all nodes, so that any node can load
# balance. Currently I am following the same logic, later this will get changed
# because of the reliability problem mentioned above.
#
# [*neutron_port*]
#  Neutron port
#
# [*neutron_protocol*]
#  Neutron protocol
#
# [*config_ip*]
#  Contrail config server IP which will be used to configure contrail api server
#  Note: This setting is used to determine ifmap server IP and discovery server
#  IP. Original contrail configuration uses local server IP for this
#  configuration. But the issue with that configuration is
#  that if any corresponding required service is down on the the node any other
#  dependant services also will be down. Need to check if this can be a load
#  balanced service.
#
# [*use_certs*]
#  Use certificate authentication for ifmap
#  Note: need confirmation on this definition
#
# [*cassandra_ip_list*]
#  An array of Cassandra server ip list
#
# [*cassandra_port*]
#   Cassandra Port. Default: 9160
#
# [*api_listen*]
#  IP Address to listen contrail api
#
# [*api_local_listen_port*]
#  Port to listen contrail API server locally
#  Default: 9100
#
# [*api_server_port*]
#  Load balanced port of contrail api server on which all services connect.
#  Default: 8082
#
# [*multi_tenancy*]
#
#
# [*memcache_servers*]
#  Optional memcache server url in <ip>:<port> form
#
# [*zk_ip_list*]
#  An array of Zookeeper IPs
#
# [*zk_port*]
#  Zookeeper port
#
# [*redis_ip*]
#  Redis server IP
#
# [*rabbitmq_ip*]
#  Rabbitmq server IP
#
# [*rabbit_user*]
#  Rabbitmq Username to connect with. Defaults to `guest`
#
# [*rabbit_password*]
#  Rabbitmq Password to connect with. Defaults to `guest`
#
# [*discovery_listen*]
#  The address on which discovery server to be listen.
#
# [*discovery_local_listen_port*]
#  Discovery server port to be listen locally
#  Default: 9110
#
# [*discovery_server_port*]
#  Load balanced port of contrail discovery server on which the clients connect
#  Default: 5998
#
# [*hc_interval*]
#  Healthcheck interval discovery server use to decide whether to disable that
#  server or not.
#  Default: 5
#
# [*manage_repo*]
#  Whether to manage opencontrail (apt) repo or not.
#
# [*enable_svcmon*]
#   Whether to enable svcmon or not. This service is only required if you are
#   using service chaining (service vms)
#
# [*interface*]
#   Network interface to use by contrail services
#
# [*collector_ip*]
#   The IP address of contrail collector.
#   Note: Not sure if it is loadblanced IP or local IP or a list of ip addresses
#
# [*analytics_data_ttl*]
#   How long analytics data to keep in hours. Default: 48 (2 days worth of data)
#
# [*router_asn*]
#   ASN that use in the router. Default: 64512
#
# [*nova_metadata_address*]
#   Nova metadata address
#
# [*nova_metadata_port*]
#   Nova Metadata port. Default: 8775
#
# [*edge_routers*]
#   Specified the Edge Routers name and IP address for IBGP peering with Contrail control
#   This is a hash reference from heira in the below format
#   contrail::edge_routers:
#      router1:{host_address:'1.1.1.1'}
#
# [*webui_ip*]
#   Contrail webui IP Address
#
# [*seed*]
#   Specifies that the current node is the seed node. Only the seed node
#   creates objects using the API to avoid race conditions.
#
# [*glance_address*]
#  Glance address
#
# [*glance_port*]
#  Glance api port, default to 9292
#
# [*glance_protocol*]
#  Glance api protocol, default to http
#
# [*nova_address*]
#  Nova Address
#
# [*nova_port*]
#  Nova port, default to 8774
#
# [*nova_protocol*]
#  Nova protocol, default to http
#
# [*cinder_address*]
#  Cinder address
#
# [*cinder_port*]
#  Cinder port, default to 8776
#
# [*cinder_protocol*]
#  Cinder protocol, default to http
#
# [*enable_analytics*]
#  Enable contrail analytics, default to true
#
# [*enable_config*]
#  Enable contrail config services, default to true
#
# [*enable_control*]
#  Enable contrail bgp/xmpp control services, defaults to true
#
# [*enable_webui*]
#  Enable contrail webui, defaults to true
#
# [*enable_ifmap*]
#  Enable ifmap, defaults to true. Ifmap is not required to be setup in case of
#  a separate node which is only running contrail analytics.
#
# [*enable_dns*] 
#  Enable contrail dns service , defaults to false. Contrail dns service can be placed on a
#  seperate node
#
#
# [*dns_port]
#  The port on which contrail-named service listens, by default this is set to 10000
#
# [*api_virtual_ip]
#  In a multinode setup, this will point to the Haproxy endpoint of the Contrail API, by default
#  it will be the localhost
# 
# [*discovery_virtual_ip]
#  In a multinode setup, this will point to the Haproxy endpoint of the Contrail discovery service, by default
#  it will be the localhost
# === Examples
#
#  class {'::contrail':
#   keystone_address           => '10.1.1.1',
#   keystone_admin_token    => 'keystone_admin_token',
#   keystone_admin_password => 'admin_user_password',
#   keystone_auth_password  => 'neutron_user_pasword',
#   manage_repo             => true,
#  }
#
# === Authors
#
# Harish Kumar <hkumar@d4devops.org>
# Pramod Venkatesh <vpramo@gmail.com>
#

class contrail (
  $keystone_admin_token,
  $keystone_admin_password,
  $keystone_auth_password,
  $keystone_admin_user,
  $keystone_auth_url,
  $edge_routers                = {},
  $nova_metadata_address       = undef,
  $nova_metadata_port          = 8775,
  $interface                   = 'eth0',
  $keystone_region             = 'RegionOne',
  $keystone_admin_tenant       = 'openstack',
  $manage_repo                 = false,
  $api_virtual_ip              = '127.0.0.1',
  $discovery_virtual_ip        = '127.0.0.1',
  $control_ip_list             = [],
  $config_package_name         = 'contrail-config-openstack',
  $package_ensure              = 'present',
  $haproxy_enabled             = true,
  $neutron_ip                  = undef,
  $neutron_port                = 9697,
  $neutron_protocol            = 'http',
  $config_ip                   = undef,
  $webui_ip                    = undef,
  $use_certs                   = false,
  $cassandra_ip_list           = [],
  $api_listen                  = '0.0.0.0',
  $api_local_listen_port       = 9100,
  $api_server_port             = 8082,
  $multi_tenancy               = false,
  $memcache_servers            = '127.0.0.1:11211',
  $zk_ip_list                  = [],
  $redis_ip                    =  undef,
  $rabbit_ip                   =  undef,
  $rabbit_user                 = 'guest',
  $rabbit_password             = 'guest',
  $discovery_listen            = '0.0.0.0',
  $discovery_local_listen_port = 9110,
  $discovery_server_port       = 5998,
  $hc_interval                 = 5,
  $enable_svcmon               = false,
  $cassandra_port              = 9160,
  $analytics_data_ttl          = 48,
  $collector_ip                = undef,
  $router_asn                  = 64512,
  $seed                        = true,

  $keystone_address            = undef,
  $keystone_admin_port         = 35357,
  $keystone_port               = 5000,
  $keystone_protocol           = 'http',

  $glance_address              = undef,
  $glance_port                 = 9292,
  $glance_protocol             = http,

  $nova_address                = undef,
  $nova_port                   = 8774,
  $nova_protocol               = http,

  $cinder_address              = undef,
  $cinder_port                 = 8776,
  $cinder_protocol             = http,

  $enable_analytics            = true,
  $enable_config               = true,
  $enable_control              = true,
  $enable_webui                = true,
  $enable_ifmap                = true,
  $enable_dns                  = false,
  $dns_port                    = '10000'
) {

  ##
  # Validate the parameters
  ##

  validate_array($control_ip_list)
  validate_array($cassandra_ip_list)
  validate_array($zk_ip_list)
  validate_bool($haproxy_enabled)
  validate_bool($use_certs)
  validate_bool($multi_tenancy)
  validate_bool($manage_repo)
  validate_bool($enable_svcmon)
  validate_bool($enable_analytics)
  validate_bool($enable_config)
  validate_bool($enable_control)
  validate_bool($enable_webui)
  validate_bool($enable_ifmap)
  validate_re($keystone_admin_port, '\d+')
  validate_re($neutron_port, '\d+')
  validate_re($api_local_listen_port, '\d+')
  validate_re($api_server_port, '\d+')
  validate_re($discovery_local_listen_port, '\d+')
  validate_re($discovery_server_port, '\d+')
  validate_re($cassandra_port, '\d+')
  validate_re($keystone_port, '\d+')
  validate_re($glance_port, '\d+')
  validate_re($cinder_port, '\d+')
  validate_re($nova_port, '\d+')
  validate_re($analytics_data_ttl, '\d+')
  validate_re($hc_interval, '\d+')
  validate_re($router_asn, '\d+')
  validate_re($nova_metadata_port, '\d+')
  validate_string($keystone_address)
  validate_string($glance_address)
  validate_string($cinder_address)
  validate_string($nova_address)
  validate_string($nova_metadata_address)
  validate_string($keystone_region)
  validate_string($keystone_admin_token)
  validate_string($keystone_admin_password)
  validate_string($keystone_auth_password)
  validate_string($redis_ip)
  validate_string($collector_ip)
  validate_string($rabbit_ip)
  validate_string($rabbit_user)
  validate_string($rabbit_password)
  validate_string($config_package_name)
  validate_string($package_ensure)
  validate_string($keystone_protocol)
  validate_string($glance_protocol)
  validate_string($cinder_protocol)
  validate_string($nova_protocol)
  validate_string($neutron_ip)
  validate_string($neutron_protocol)
  validate_string($config_ip)
  validate_string($webui_ip)
  validate_string($api_listen)
  validate_string($memcache_servers)
  validate_hash($edge_routers)
  validate_string($api_virtual_ip)
  validate_string($discovery_virtual_ip)

  ##
  # Declaring anchors
  ##
  anchor {'contrail::start':}
  anchor {'contrail::end_base_services':
    before  => Anchor['contrail::end'],
    require => Anchor['contrail::start'],
  }
  anchor {'contrail::end':}

  ##
  # Fail if the interface provided doesn't have any IP address associated
  ##

  $contrail_ip = inline_template("<%= scope.lookupvar('ipaddress_' + @interface) %>")

  if empty($contrail_ip) {
    fail("Interface provided (${interface}) doesn't have any IP address associated")
  }

  ##
  # Set defaults
  ##

  if ! $nova_metadata_address {
    if $contrail_ip =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ {
      $nova_metadata_address_orig = $contrail_ip
    } else {
      $nova_metadata_address_orig = dns_resolve($contrail_ip)
    }
  } else {
    if $nova_metadata_address =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ {
      $nova_metadata_address_orig = $nova_metadata_address
    } else {
      $nova_metadata_address_orig = dns_resolve($nova_metadata_address)
    }
  }

  if ! $keystone_address {
    $keystone_address_orig = $contrail_ip
  } else {
    $keystone_address_orig = $keystone_address
  }

  if ! $glance_address {
    $glance_address_orig = $contrail_ip
  } else {
    $glance_address_orig = $glance_address
  }

  if ! $cinder_address {
    $cinder_address_orig = $contrail_ip
  } else {
    $cinder_address_orig = $cinder_address
  }

  if ! $nova_address {
    $nova_address_orig = $contrail_ip
  } else {
    $nova_address_orig = $nova_address
  }

  if empty($control_ip_list) {
    $control_ip_list_orig = [$contrail_ip]
  } else {
    $control_ip_list_orig = $control_ip_list
  }

  if ! $neutron_ip {
    $neutron_ip_orig = $contrail_ip
  } else {
    $neutron_ip_orig = $neutron_ip
  }

  if ! $config_ip {
    $config_ip_orig = $contrail_ip
  } else {
    $config_ip_orig = $config_ip
  }

  if ! $webui_ip {
    $webui_ip_orig = $contrail_ip
  } else {
    $webui_ip_orig = $webui_ip
  }

  if ! $collector_ip {
    $collector_ip_orig = $contrail_ip
  } else {
    $collector_ip_orig = $collector_ip
  }

  if empty($cassandra_ip_list) {
    $cassandra_ip_list_orig = [$contrail_ip]
  } else {
    $cassandra_ip_list_orig = $cassandra_ip_list
  }

  if empty($zk_ip_list) {
    $zk_ip_list_orig = [$contrail_ip]
  } else {
    $zk_ip_list_orig = $zk_ip_list
  }

  if ! $redis_ip {
    $redis_ip_orig = $contrail_ip
  } else {
    $redis_ip_orig = $redis_ip
  }

  if ! $rabbit_ip {
    $rabbit_ip_orig = $contrail_ip
  } else {
    $rabbit_ip_orig = $rabbit_ip
  }


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


  ##
  # contrail::system_config does operating system parameter changes,
  #       and make the system ready to run contrail services
  ##

  class {'contrail::system_config':
    contrail_ip => $contrail_ip,
  }

  Anchor['contrail::start'] ->
  Class['contrail::system_config'] ->
  Anchor['contrail::end_base_services']

  ##
  # Manage contrail ifmap, if enabled
  # ifmap is not required to install on the node in case of separate
  # contrail-analytics node.
  ##
  if $enable_ifmap {
    class {'contrail::ifmap':
      control_ip_list => $control_ip_list_orig
    }

    Anchor['contrail::start'] ->
    Class['contrail::ifmap'] ->
    Anchor['contrail::end_base_services']
  }

  ##
  # Manage contrail config services
  ##

  if $enable_config {
    class {'contrail::config':
      keystone_host               => $keystone_address_orig,
      nova_metadata_address       => $nova_metadata_address_orig,
      nova_metadata_port          => $nova_metadata_port,
      keystone_admin_user         => $keystone_admin_user,
      keystone_admin_token        => $keystone_admin_token,
      keystone_admin_password     => $keystone_admin_password,
      keystone_auth_password      => $keystone_auth_password,
      keystone_admin_tenant       => $keystone_admin_tenant,
      keystone_region             => $keystone_region,
      keystone_auth_url           => $keystone_auth_url,
      package_name                => $config_package_name,
      package_ensure              => $package_ensure,
      keystone_admin_port         => $keystone_admin_port,
      keystone_protocol           => $keystone_protocol,
      haproxy_enabled             => $haproxy_enabled,
      neutron_ip                  => $neutron_ip_orig,
      neutron_port                => $neutron_port,
      neutron_protocol            => $neutron_protocol,
      config_ip                   => $config_ip_orig,
      use_certs                   => $use_certs,
      cassandra_ip_list           => $cassandra_ip_list_orig,
      api_virtual_ip              => $api_virtual_ip,
      api_listen                  => $api_listen,
      api_local_listen_port       => $api_local_listen_port,
      api_server_port             => $api_server_port,
      multi_tenancy               => $multi_tenancy,
      memcache_servers            => $memcache_servers,
      zk_ip_list                  => $zk_ip_list_orig,
      redis_ip                    => $redis_ip_orig,
      rabbit_ip                   => $rabbit_ip_orig,
      rabbit_user                 => $rabbit_user,
      rabbit_password             => $rabbit_password,
      discovery_virtual_ip        => $discovery_virtual_ip,
      discovery_listen            => $discovery_listen,
      discovery_local_listen_port => $discovery_local_listen_port,
      discovery_server_port       => $discovery_server_port,
      hc_interval                 => $hc_interval,
      enable_svcmon               => $enable_svcmon,
      router_asn                  => $router_asn,
      edge_routers                => $edge_routers,
      contrail_ip                 => $contrail_ip,
      seed                        => $seed,
    }

    Anchor['contrail::end_base_services'] ->
    Class['contrail::config'] ->
    Anchor['contrail::end']
  }

  ##
  # Contrail control services
  ##

  if $enable_control {
    class {'contrail::control':
      control_ip_list => $control_ip_list_orig,
      config_ip       => $config_ip_orig,
      api_virtual_ip  => $api_virtual_ip,
      discovery_virtual_ip => $discovery_virtual_ip,
      contrail_ip     => $contrail_ip,
      enable_dns      => $enable_dns,
      dns_port        => $dns_port
    }

    Anchor['contrail::end_base_services'] ->
    Class['contrail::control'] ->
    Anchor['contrail::end']
  }

  ##
  # Contrail analytics collector
  ##
  if $enable_analytics {
    class {'contrail::collector':
      contrail_ip          => $contrail_ip,
      collector_ip         => $collector_ip_orig,
      config_ip            => $config_ip_orig,
      api_virtual_ip       => $api_virtual_ip,
      discovery_virtual_ip => $discovery_virtual_ip,
      analytics_data_ttl   => $analytics_data_ttl,
      cassandra_ip_list    => $cassandra_ip_list_orig,
      redis_ip             => $redis_ip_orig,
      cassandra_port       => $cassandra_port,
    }

    Anchor['contrail::end_base_services'] ->
    Class['contrail::collector'] ->
    Anchor['contrail::end']
  }

  ##
  # Contrail webui setup
  ##
  if $enable_webui {
    class {'contrail::webui':
      package_ensure     => $package_ensure,
      api_virtual_ip     => $api_virtual_ip,
      discovery_virtual_ip => $discovery_virtual_ip,
      contrail_ip        => $contrail_ip,
      webui_ip           => $webui_ip_orig,
      config_ip          => $config_ip_orig,
      analytics_data_ttl => $analytics_data_ttl,
      cassandra_ip_list  => $cassandra_ip_list_orig,
      redis_ip           => $redis_ip_orig,
      glance_address     => $glance_address_orig,
      glance_port        => $glance_port,
      glance_protocol    => $glance_protocol,
      nova_address       => $nova_address_orig,
      nova_port          => $nova_port,
      nova_protocol      => $nova_protocol,
      keystone_address   => $keystone_address_orig,
      keystone_port      => $keystone_port,
      keystone_protocol  => $keystone_protocol,
      cinder_address     => $cinder_address_orig,
      cinder_port        => $cinder_port,
      cinder_protocol    => $cinder_protocol,
      neutron_port       => $neutron_port,
      neutron_protocol   => $neutron_protocol,
      collector_ip       => $collector_ip_orig,
    }

    ##
    # anchor contrail::end_base_services will cause dep cycle as webui have a
    # apt-pin which will have problems on package installation in base_services
    # like ifmap, so adding dep to contrail::start for now.
    ##
    Anchor['contrail::start'] ->
    Class['contrail::webui'] ->
    Anchor['contrail::end']
  }
}
