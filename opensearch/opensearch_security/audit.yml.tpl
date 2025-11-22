_meta:
  type: "audit"
  config_version: 2

config:
  enabled: ${tobool(try(opensearch_cluster.audit.enabled, false))}

  compliance:
%{ if try(opensearch_cluster.audit.enabled, false) ~}
    enabled: true
    internal_config: true
    write_metadata_only: false
    write_log_diffs: true
    write_watched_indices:
      - ".opendistro_security"
%{ else ~}
    enabled: false
%{ endif ~}
