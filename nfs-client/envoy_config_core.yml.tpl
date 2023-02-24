node:
  cluster: nfs_tunnel
  id: ${proxy.client_name}

dynamic_resources:
  cds_config:
    resource_api_version: V3
    path_config_source:
      path: /etc/nfs-tunnel/envoy/clusters.yml
  lds_config:
    resource_api_version: V3
    path_config_source:
      path: /etc/nfs-tunnel/envoy/listeners.yml