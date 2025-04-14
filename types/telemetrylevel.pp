# @summary A string that conforms to the ProSA `TelemetryLevel` syntax.
#
# A string that conforms to the ProSA `TelemetryLevel` syntax.
# Different levels can be specified for individual _metrics_, _traces_, and _logs_.
#
# The levels are (in order of decreasing significance):
# * `error`
# * `warn`
# * `info`
# * `debug`
# * `trace`
# * `off`
#
# ProSA accept non case sensitive levels (like this type).
#
# @see https://docs.rs/prosa-utils/latest/prosa_utils/config/tracing/enum.TelemetryLevel.html
type ProSA::TelemetryLevel = Pattern[/\A(?i:error|warn|info|debug|trace|off)\Z/]
