resources:
%{ for idx, backend in reverse_proxy.backends ~}
  - "@type": type.googleapis.com/envoy.config.cluster.v3.Cluster
    name: http_secutiry_reverse_proxy_cluster_${idx}
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
          max_connections: ${reverse_proxy.max_connections}
          max_pending_requests: ${reverse_proxy.max_connections}
          max_requests: ${reverse_proxy.max_connections}
          max_retries: 3
          track_remaining: true
    load_assignment:
      cluster_name: http_secutiry_reverse_proxy_cluster_${idx}
      endpoints:
        - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: ${backend.ip}
                    port_value: ${backend.port}
%{ endfor ~}