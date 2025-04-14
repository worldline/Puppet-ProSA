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

  $prosa_name      = regsubst("prosa-${servername}", '[ \t.:/]+', '_', 'G')
  $service_name    = 'prosa'
  $bin_path        = '/usr/local/bin/prosa'
  $conf_dir        = '/etc/prosa'
  $user            = 'prosa'
  $group           = 'prosa'
  $telemetry_level = 'warn'
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
