cluster.name: ${opensearch_cluster.cluster_name}
node.name: ${opensearch_host.host_name}
%{ if opensearch_host.manager ~}
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
cluster.initial_master_nodes:
%{ for seed_host in opensearch_cluster.seed_hosts ~}
  - ${seed_host}
%{ endfor ~}
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