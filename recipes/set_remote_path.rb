# TODO: Replace #end_with?

require 'rexml/document'
require 'open-uri'

# RULES

omnibus_version = node[:omnibus_updater][:version]
unless(omnibus_version)
  doc = REXML::Document.new(open(node[:omnibus_updater][:base_uri]))
  keys = REXML::XPath.match(doc, '//Key').map(&:text)
end

platform_name = node.platform
case node.platform_family
when 'debian'
  if(node.platform == 'ubuntu')
    platform_version = case node.platform_version
    when '10.10', '10.04'
      '10.10'
    when '12.04', '11.10', '11.04'
      '11.04'
    else
      raise 'Unsupported ubuntu version for deb packaged omnibus'
    end
  else
    platform_version = case pv = node.platform_version.split('.').first
    when '6', '5'
      '6.0.1'
    else
      pv
    end
  end
when 'fedora', 'rhel'
  platform_version = case node.platform_version.split('.').first
  when '5'
    '5.7'
  when '6'
    '6.2'
  else
    raise 'Unsupported version'
  end
  platform_name = 'el'
else
  platform_version = node.platform_version
end

if(node[:omnibus_updater][:install_via])
  install_via = node[:omnibus_updater][:install_via]
else
  install_via = case node.platform_family
  when 'debian'
    'deb'
  when 'fedora', 'rhel', 'centos'
    'rpm'
  else
    'script'
  end
end
case install_via
when 'deb'
  arch = node.kernel.machine.include?('64') ? 'amd64' : 'i386'
  if(node[:omnibus_updater][:version])
    file_name = "chef-full_#{node[:omnibus_updater][:version]}_#{arch}.deb"
  else
    file_name = keys.find_all{|k| 
      k.include?(arch) && k.include?('chef-full') && k.end_with?('.deb') && k.include?(platform_name)
    }.sort.last.split('/').last
  end

when 'rpm'
  if(node[:omnibus_updater][:version])
    file_name = "chef-full-#{node[:omnibus_updater][:version]}.#{node.kernel.machine}.rpm"
  else
    file_name = keys.find_all{|k| 
      k.include?(node.kernel.machine) && k.include?('chef-full') && k.end_with?('.rpm') && k.include?(platform_name)
    }.sort.last.split('/').last
  end
else
  file_name = "chef-full-#{node[:omnibus_updater][:version]}-#{platform_name}-#{platform_version}-#{node.kernel.machine}.sh"
end

remote_omnibus_file = File.join(
  node[:omnibus_updater][:base_uri],
  platform_name + '-' +
  platform_version + '-' +
  node.kernel.machine,
  file_name
)

unless(remote_omnibus_file == node[:omnibus_updater][:full_uri])
  node.set[:omnibus_updater][:full_uri] = remote_omnibus_file
  Chef::Log.info "Omnibus remote file location: #{remote_omnibus_file}"
end
