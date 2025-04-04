# @summary
#   Installs and configures ProSA service.
#
# @api private
class prosa::service (
  String $prosa_name                       = $prosa::params::prosa_name,
  String $service_name                     = $prosa::params::service_name,
  Stdlib::Absolutepath $service_binary     = $prosa::params::bin_path,
  Stdlib::Absolutepath $app_conf           = $prosa::params::conf_dir,
  String $user                             = $prosa::params::user,
  String $group                            = $prosa::params::group,
  Boolean $service_enable                  = true,
  Variant[Boolean, String] $service_ensure = 'running',
  Boolean $service_manage                  = true
) {
  # The base class must be included first because parameter defaults depend on it
  if ! defined(Class['prosa::params']) {
    fail('You must include the prosa::params class before using any ProSA defined resources')
  }
  case $service_ensure {
    true, false, 'running', 'stopped': {
      $_service_ensure = $service_ensure
    }
    default: {
      $_service_ensure = undef
    }
  }

  # If the service provider is systemd
  if find_file('/usr/lib/systemd/system') {
    file { "/usr/lib/systemd/system/${service_name}.service":
      ensure  => file,
      owner   => 'root',
      group   => $prosa::params::root_group,
      mode    => '0644',
      content => epp('prosa/service.epp', {
          'prosa_name' => $prosa_name,
          'user'       => $user,
          'group'      => $group,
          'bin_path'   => $service_binary,
          'conf_path'  => $app_conf,
      }),
      replace => true,
    }

    if $service_manage {
      service { $service_name:
        ensure  => $_service_ensure,
        enable  => $service_enable,
        require => File["/usr/lib/systemd/system/${service_name}.service"],
      }
    }
  }
}
