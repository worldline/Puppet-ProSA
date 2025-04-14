# @summary
#   Allows specialised configurations for ProSA processors
#
# @example
#   class { 'prosa':
#     default_vhost     => false,
#     default_ssl_vhost => false,
#   }
#
# @param adaptor_config_path
#   For some ProSA adaptor, they need to have a configuration in addition to processor.
#   If needed you need to specify the path of it.
#
# @param adaptor_settings
#   All settings of the adaptor if needed.
#   The keys/values are depending of the adaptor.
#   The `adaptor_config_path` should be defined if it's sets.
#
# @param proc_restart_duration_period
#   Period in milliseconds of processors restarts when an error is detected
#
# @param proc_max_restart_period
#   Period in seconds of the maximum wait duration for a processor restart
#
# @param proc_settings
#   All settings of the processor.
#   The keys/values are depending of the processor.
#
# @param config_file_mode
#   Permissions mode for the processor configuration file
#   The file should be read at least by the ProSA process.
#   But can be reduced to avoid any configuration leak.
#   If not set, the permission will be '0644'.
#
define prosa::proc (
  Optional[Stdlib::Absolutepath] $adaptor_config_path          = undef,
  Optional[Hash] $adaptor_settings                             = undef,
  Optional[Integer[0, 86400000]] $proc_restart_duration_period = undef,
  Optional[Integer[10, 604800]] $proc_max_restart_period       = undef,
  Hash $proc_settings                                          = {},
  Optional[String] $config_file_mode                           = undef,
) {
  # The base class must be included first because it is used by parameter defaults
  if ! defined(Class['prosa']) {
    fail('You must include the prosa base class before using any prosa defined resources')
  }
  $proc_name = regsubst($name, '[ \t.:/]+', '_', 'G')

  $hash_adaptor_config_path = $adaptor_config_path ? {
    undef   => {},
    default => { 'adaptor_config_path' => $adaptor_config_path },
  }
  $hash_proc_restart_duration_period = $proc_restart_duration_period ? {
    undef   => {},
    default => { 'proc_restart_duration_period' => $proc_restart_duration_period },
  }
  $hash_proc_max_restart_period = $proc_max_restart_period ? {
    undef   => {},
    default => { 'proc_max_restart_period' => $proc_max_restart_period },
  }

  # Write processor YAML configuration
  file { "${prosa::conf_dir}/${proc_name}.yml":
    ensure  => file,
    owner   => $prosa::user,
    group   => $prosa::group,
    mode    => $config_file_mode,
    content => stdlib::to_yaml({ "${proc_name}" => $hash_adaptor_config_path + $hash_proc_restart_duration_period + $hash_proc_max_restart_period + $proc_settings }, { header => false, indentation => 2 }),
    require => File[$prosa::conf_dir],
    notify  => Class['prosa::service'],
  }

  # Write adaptor YAML configuration if needed
  if $adaptor_config_path {
    file { $adaptor_config_path:
      ensure  => file,
      owner   => $prosa::user,
      group   => $prosa::group,
      mode    => $config_file_mode,
      content => stdlib::to_yaml($adaptor_settings, { header => false, indentation => 2 }),
      require => File[$prosa::conf_dir],
      notify  => Class['prosa::service'],
    }
  }
}
