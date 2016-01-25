require_relative '../contrailBGP'

Puppet::Type.type(:contrail_fip_pool).provide(
  :provisioner,
  :parent => Puppet::Provider::ContrailBGP
) do

  commands  :create_fip => '/usr/share/contrail-utils/create_floating_pool.py',
            :use_fip => '/usr/share/contrail-utils/use_floating_pool.py'

  def getUrl
    'http://' + resource[:api_server_address] + ':' + resource[:api_server_port] + '/floating-ip-pools'
  end

  def exists?
    !getObject(getUrl,"#{resource[:network_fqname]}:#{resource[:name]}").nil?
  end

  def getObject(url,name)
    getUrlData(url)['floating-ip-pools'].each do |i|
      if i['fq_name'].join(':') == name
        @fip_obj = getUrlData(i['href'])['floating-ip-pool']
      end
    end
    return  @fip_obj
  end

  def create
    create_fip('--public_vn_name',resource[:network_fqname],'--floating_ip_pool_name',resource[:name],'--api_server_ip',resource[:api_server_address],'--api_server_port',resource[:api_server_port],'--admin_user',resource[:admin_user],'--admin_password',resource[:admin_password],'--admin_tenant',resource[:admin_tenant])
    resource[:tenants].each do |x|
      use_fip('--project_name', "default-domain:#{x}", '--floating_ip_pool_name',"#{resource[:network_fqname]}:#{resource[:name]}", '--api_server_ip',resource[:api_server_address])
    end
  end

  ##
  #TODO: as of now existing fip pool is not supported. it need more investigation and testing to avoid contrail stale data.
  ##
  def destroy
    fail('Destroying fip pool is not supported using contrail api')
  end

  def tenants
    if getObject(getUrl,resource[:name]).include?('project_back_refs')
      getObject(getUrl,resource[:name])['project_back_refs'].collect { |x| x['to'].last}
    else
      []
    end
  end

  ##
  # TODO: As of now, removal of existing tenant from a fip pool is not supported, it need more investigation to enable it.
  ##
  def tenants=(value)
    if getObject(getUrl,resource[:name]).include?('project_back_refs')
      tenants_to_add = resource[:tenants] - getObject(getUrl,resource[:name])['project_back_refs'].collect { |x| x['to'].join(':')}
    else
      tenants_to_add = resource[:tenants]
    end
    tenants_to_add.each do |x|
      use_fip('--project_name', "default-domain:#{x}", '--floating_ip_pool_name',"#{resource[:network_fqname]}:#{resource[:name]}", '--api_server_ip',"#{resource[:api_server_address]}")
    end
  end

end
