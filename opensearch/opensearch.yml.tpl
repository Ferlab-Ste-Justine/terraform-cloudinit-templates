cluster.name: ${opensearch_cluster.cluster_name}
node.name: ${opensearch_host.host_name}
%{ if opensearch_host.cluster_manager ~}
node.roles:
  - cluster_manager
%{ else ~}
node.roles:
  - data
  - ingest
%{ endif ~}
network.host: ["${opensearch_host.bind_ip}", _local_]
%{ if length(opensearch_host.extra_http_bind_ips) > 0 ~}
http.bind_host: ["${opensearch_host.bind_ip}", ${join(", ", [for ip in opensearch_host.extra_http_bind_ips: "\"${ip}\""])}, _local_]
%{ endif ~}
%{ if opensearch_host.initial_cluster ~}
cluster.initial_cluster_manager_nodes:
%{ if length(opensearch_cluster.initial_cluster_manager_nodes) > 0 ~}
%{ for manager in opensearch_cluster.initial_cluster_manager_nodes ~}
  - ${manager}
%{ endfor ~}
%{ else ~}
%{ for seed_host in opensearch_cluster.seed_hosts ~}
  - ${seed_host}
%{ endfor ~}
%{ endif ~}
%{ endif ~}
discovery.seed_hosts:
%{ for seed_host in opensearch_cluster.seed_hosts ~}
  - ${seed_host}
%{ endfor ~}
plugins.security.ssl.http.enabled: true
%{ if opensearch_cluster.verify_domains ~}
plugins.security.ssl.transport.enforce_hostname_verification: true
plugins.security.ssl.transport.resolve_hostname: true
%{ else ~}
plugins.security.ssl.transport.enforce_hostname_verification: false
plugins.security.ssl.transport.resolve_hostname: false
%{ endif ~}
%{ if opensearch_cluster.basic_auth_enabled ~}
plugins.security.ssl.http.clientauth_mode: OPTIONAL
%{ else ~}
plugins.security.ssl.http.clientauth_mode: REQUIRE
%{ endif ~}
plugins.security.ssl.transport.pemkey_filepath: /etc/opensearch/server-certs/server-key-pk8.pem
plugins.security.ssl.transport.pemcert_filepath: /etc/opensearch/server-certs/server.crt
plugins.security.ssl.transport.pemtrustedcas_filepath: /etc/opensearch/ca-certs/ca.crt
plugins.security.ssl.http.pemkey_filepath: /etc/opensearch/server-certs/server-key-pk8.pem
plugins.security.ssl.http.pemcert_filepath: /etc/opensearch/server-certs/server.crt
plugins.security.ssl.http.pemtrustedcas_filepath: /etc/opensearch/ca-certs/ca.crt
plugins.security.nodes_dn:
  - "CN=${opensearch_cluster.auth_dn_fields.node_common_name},O=${opensearch_cluster.auth_dn_fields.organization}"
plugins.security.authcz.admin_dn:
  - "CN=${opensearch_cluster.auth_dn_fields.admin_common_name},O=${opensearch_cluster.auth_dn_fields.organization}"
plugins.security.restapi.roles_enabled: ["all_access"]
prometheus.metric_name.prefix: "opensearch_"
prometheus.indices: true
prometheus.cluster.settings: true
prometheus.nodes.filter: "_all"

%{ if try(opensearch_cluster.audit.enabled, false) ~}
%{ if length(try(opensearch_cluster.audit.external.http_endpoints, [])) > 0 ~}
plugins.security.audit.type: external_opensearch
%{ else ~}
plugins.security.audit.type: internal_opensearch
%{ endif ~}

plugins.security.audit.config.enable_rest: true
plugins.security.audit.config.enable_transport: true

plugins.security.audit.config.index: ${opensearch_cluster.audit.index}
plugins.security.audit.config.type: "auditlog"
plugins.security.audit.config.exclude_sensitive_headers: true
%{ if length(try(opensearch_cluster.audit.ignore_users, [])) > 0 ~}
plugins.security.audit.config.ignore_users: ["${join("\", \"", opensearch_cluster.audit.ignore_users)}"]
%{ else ~}
plugins.security.audit.config.ignore_users: NONE
%{ endif ~}
%{ if length(try(opensearch_cluster.audit.ignore_requests, [])) > 0 ~}
plugins.security.audit.config.ignore_requests: ["${join("\", \"", opensearch_cluster.audit.ignore_requests)}"]
%{ else ~}
plugins.security.audit.config.ignore_requests: NONE
%{ endif ~}

%{ if length(try(opensearch_cluster.audit.external.http_endpoints, [])) > 0 ~}
plugins.security.audit.config.http_endpoints: [${join(", ", [for endpoint in opensearch_cluster.audit.external.http_endpoints: "\"${endpoint}\""])}]

plugins.security.audit.config.enable_ssl: true
plugins.security.audit.config.verify_hostnames: true
%{ if try(opensearch_cluster.audit.external.auth.ca_cert, "") != "" ~}
plugins.security.audit.config.pemtrustedcas_filepath: /etc/opensearch/audit-external/ca.crt
%{ else ~}
plugins.security.audit.config.pemtrustedcas_filepath: /etc/opensearch/ca-certs/ca.crt
%{ endif ~}

%{ if try(opensearch_cluster.audit.external.auth.client_cert, "") != "" && try(opensearch_cluster.audit.external.auth.client_key, "") != "" ~}
plugins.security.audit.config.enable_ssl_client_auth: true
plugins.security.audit.config.pemcert_filepath: /etc/opensearch/audit-external/client.crt
plugins.security.audit.config.pemkey_filepath: /etc/opensearch/audit-external/client-key-pk8.pem
%{ else ~}
plugins.security.audit.config.username: ${try(opensearch_cluster.audit.external.auth.username, "")}
plugins.security.audit.config.password: ${try(opensearch_cluster.audit.external.auth.password, "")}
%{ endif ~}
%{ endif ~}
%{ endif ~}
