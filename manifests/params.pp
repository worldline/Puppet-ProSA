# @summary
#   This class manages ProSA parameters
#
# @api private
class prosa::params {
  if($facts['networking']['fqdn']) {
    $servername = $facts['networking']['fqdn']
  } else {
    $servername = $facts['networking']['hostname']
  }

  $prosa_name      = lookup('prosa::name', String, undef, regsubst("prosa-${servername}", '[ \t.:/]+', '_', 'G'))
  $service_name    = 'prosa'
  $bin_path        = '/usr/local/bin/prosa'
  $conf_dir        = '/etc/prosa'
  $bin_repo        = lookup('prosa::bin_repo', Optional[String], undef, undef)
  $user            = 'prosa'
  $group           = 'prosa'
  $telemetry_level = lookup('prosa::telemetry_level', ProSA::TelemetryLevel, undef, 'warn')
  $observability   = {
    'metrics' => {
      'stdout' => {
        'level' => 'info',
      },
    },
    'traces' => {
      'stdout' => {
        'level' => 'info',
      },
    },
    'logs' => {
      'stdout' => {
        'level' => 'info',
      },
    },
  }

  $root_group = 'root'

  if $facts['os']['family'] == 'FreeBSD' {
    $root_group       = 'wheel'
  }
}
