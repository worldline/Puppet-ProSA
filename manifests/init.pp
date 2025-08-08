# @summary
#   Guides the basic setup and installation of ProSA on your system.
#
# A description of what this class does
#
# @example
#   class { 'prosa': }
#
# @param prosa_name
#   The name of your ProSA. It take this name to advertise himself.
#   This name is sometime very important for some processors.
#
# @param service_name
#   Sets the name of the ProSA service.
#
# @param bin_repo
#   Link to the binary repository where the ProSA binary can be find.
#   See [Puppet File source attribute](https://www.puppet.com/docs/puppet/8/types/file.html#file-attribute-source) to set this parameter
#
# @param bin_path
#   Sets the path where the ProSA binary will be located.
#
# @param log_dir
#   Sets the directory where the ProSA logs files are located.
#
# @param conf_dir
#   Sets the directory where the ProSA configuration files are located.
#
# @param service_enable
#   Determines whether Puppet enables the ProSA service when the system is booted.
#
# @param service_manage
#   Determines whether Puppet manages the ProSA service's state.
#
# @param service_ensure
#   Determines whether Puppet should make sure the service is running. 
#   Valid values are: `true` (or `running`) or `false` (or `stopped`).<br />
#   The `false` or `stopped` values set the ProSA service resource's `ensure` parameter 
#   to `false`, which is useful when you want to let the service be managed by another 
#   application.<br />
#
# @param manage_user
#   When `false`, stops Puppet from creating the user resource.<br />
#   This is for instances when you have a user, created from another Puppet module, you want 
#   to use to run ProSA. Without this parameter, attempting to use a previously established 
#   user would result in a duplicate resource error.
#
# @param manage_group
#   When `false`, stops Puppet from creating the group resource.<br />
#   If you have a group created from another Puppet module that you want to use to run ProSA, 
#   set this to `false`. Without this parameter, attempting to use a previously established 
#   group results in a duplicate resource error.
#
# @param user
#   Change the user that ProSA uses to run.
#   To prevent Puppet from managing the user, set the `manage_user` parameter to `false`.
#
# @param group
#   Changes the group ID that ProSA uses to run.
#   To prevent Puppet from managing the user, set the `manage_user` parameter to `false`.
#
# @param telemetry_level
#   Configures the ProSA [TelemetryLevel](https://docs.rs/prosa-utils/latest/prosa_utils/config/tracing/enum.TelemetryLevel.html) directive
#   which adjusts the verbosity of telemetry messages recorded.
#
# @param observability
#   Configures the ProSA [Observability](https://docs.rs/prosa-utils/latest/prosa_utils/config/observability/struct.Observability.html) directive
#   which configure metrics, traces and logs export.
#
class prosa (
  String $prosa_name                                              = $prosa::params::prosa_name,
  String $service_name                                            = $prosa::params::service_name,
  Optional[String] $bin_repo                                      = undef,
  Stdlib::Absolutepath $bin_path                                  = $prosa::params::bin_path,
  Stdlib::Absolutepath $log_dir                                   = '/var/log',
  Stdlib::Absolutepath $conf_dir                                  = $prosa::params::conf_dir,
  Boolean $service_enable                                         = true,
  Boolean $service_manage                                         = true,
  Variant[Stdlib::Ensure::Service, Boolean] $service_ensure       = 'running',
  Boolean $manage_user                                            = true,
  Boolean $manage_group                                           = true,
  String $user                                                    = $prosa::params::user,
  String $group                                                   = $prosa::params::group,
  ProSA::TelemetryLevel $telemetry_level                          = $prosa::params::telemetry_level,
  Hash[String, Hash[String, Hash[String, String]]] $observability = $prosa::params::observability,
) inherits prosa::params {
  # declare ProSA user and group
  if $manage_group {
    group { $group:
      ensure => present,
    }
  }
  if $manage_user {
    user { $user:
      ensure  => present,
      comment => 'ProSA user',
      gid     => $group,
    }
  }

  # Ensure configuration folder exist
  file { $conf_dir:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }

  # Create ProSA main configuration file
  file { "${conf_dir}/prosa.yml":
    ensure  => file,
    owner   => $user,
    group   => $group,
    mode    => '0644',
    content => epp('prosa/prosa.yml.epp', {
        'prosa_name'      => $prosa_name,
        'telemetry_level' => $telemetry_level,
        'observability'   => $observability,
    }),
    require => File[$conf_dir],
    notify  => Class['prosa::service'],
  }

  # Download ProSA binary from an external binary repository
  if $bin_repo {
    file { $bin_path:
      ensure => file,
      owner  => 'root',
      group  => $prosa::params::root_group,
      mode   => '0755',
      source => $bin_repo,
      notify => Class['prosa::service'],
    }
  }

  # Declare ProSA service
  class { 'prosa::service':
    prosa_name     => $prosa_name,
    service_name   => $service_name,
    service_binary => $bin_path,
    app_conf       => $conf_dir,
    user           => $user,
    group          => $group,
    service_enable => $service_enable,
    service_ensure => $service_ensure,
    service_manage => $service_manage,
  }
}
