node:
  cluster: http_security_reverse_proxy
  id: ${reverse_proxy.server_name}

dynamic_resources:
  cds_config:
    resource_api_version: V3
    path_config_source:
      path: /etc/http-security-reverse-proxy/envoy/clusters.yml
  lds_config:
    resource_api_version: V3
    path_config_source:
      path: /etc/http-security-reverse-proxy/envoy/listeners.yml