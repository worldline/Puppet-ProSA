# @summary The ProSA `observability` settings managed by this module.
#
# * `endpoint`: shared HTTP endpoint (`address:port`) serving Prometheus metrics and health probes.
# * `metrics`, `traces`, `logs`: exporters settings, indexed by exporter (`stdout`, `otlp`, and the legacy `prometheus` for metrics).
#
# @see https://docs.rs/prosa-utils/latest/prosa_utils/config/observability/struct.Observability.html
type ProSA::Observability = Struct[{
    Optional['endpoint'] => String[1],
    Optional['metrics']  => Hash[String, Hash[String, String]],
    Optional['traces']   => Hash[String, Hash[String, String]],
    Optional['logs']     => Hash[String, Hash[String, String]],
}]
