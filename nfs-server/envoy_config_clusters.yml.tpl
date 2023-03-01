resources:
  - "@type": type.googleapis.com/envoy.config.cluster.v3.Cluster
    name: nfs_server
    type: STATIC
    lb_policy: ROUND_ROBIN
    health_checks:
      - timeout: "10s"
        interval: "30s"
        healthy_threshold: 1
        unhealthy_threshold: 3
        tcp_health_check: {}
    circuit_breakers:
      thresholds:
        - priority: DEFAULT
          max_connections: ${proxy.max_connections}
          max_pending_requests: ${proxy.max_connections}
          max_requests: ${proxy.max_connections}
          max_retries: 3
          track_remaining: true
    load_assignment:
      cluster_name: nfs_server
      endpoints:
        - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: 127.0.0.1
                    port_value: 2049