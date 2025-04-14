# @summary
#   Creates `prosa::proc` defined types.
#
# @example To create a [ProSA processor](https://docs.rs/prosa/latest/prosa/core/proc/index.html) `stub-1`
#   class { 'prosa::processors':
#     processors => {
#       'stub-1' => {
#         'adaptor_config_path'          => undef,
#         'proc_restart_duration_period' => undef,
#         'proc_max_restart_period'      => undef,
#         'proc_settings'                     => {
#           'service_names' => ['test'],
#         },
#       },
#     },
#   }
#
# @param processors
#   A hash, where the key represents the processor name and the value represents a hash of 
#   `prosa::proc` defined type's parameters.
#
class prosa::processors (
  Hash $processors = {},
) {
  include prosa
  create_resources('prosa::proc', $processors)
}
