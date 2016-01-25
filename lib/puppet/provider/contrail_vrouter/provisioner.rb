require 'puppet/provider/contrailBGP'

Puppet::Type.type(:contrail_vrouter).provide(
  :provisioner,
  :parent => Puppet::Provider::ContrailBGP
) do

  commands  :provision_vrouter => '/usr/sbin/contrail-provision-vrouter'

  def getUrl
    'http://' + resource[:api_server_address] + ':' + resource[:api_server_port] + '/virtual-routers'
  end

  def getObject(url,name)
    @vrouter_obj ||= {}
    @vrouter_obj['virtual_router_ip_address'] || getUrlData(url)['virtual-routers'].each do |i|
      if i['fq_name'].include?(name)
        @vrouter_obj = getUrlData(i['href'])['virtual-router']
        return @vrouter_obj
      end
    end
    return  @vrouter_obj
  end

  def exists?
     !getObject(getUrl,resource[:name]).empty?
  end

  def create
    provision_vrouter(
      '--admin_user',resource[:admin_user],
      '--admin_password',resource[:admin_password],
      '--admin_tenant_name',resource[:admin_tenant],
      '--api_server_ip', resource[:api_server_address],
      '--api_server_port',resource[:api_server_port],
      '--host_name',resource[:name],
      '--host_ip',resource[:host_address],
      '--oper add')
  end

  def destroy
    provision_vrouter(
      '--admin_user',resource[:admin_user],
      '--admin_password',resource[:admin_password],
      '--admin_tenant_name',resource[:admin_tenant],
      '--api_server_ip', resource[:api_server_address],
      '--api_server_port',resource[:api_server_port],
      '--host_name',resource[:name],
      '--host_ip',resource[:host_address],
      '--oper del')
  end

  def host_address
    getElement(getUrl,resource[:name],'virtual_router_ip_address')
  end

  def host_address=(value)
    destroy
    create
  end

end
