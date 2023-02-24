resources:
  - "@type": type.googleapis.com/envoy.config.cluster.v3.Cluster
    name: nfs_server
    type: STRICT_DNS
%{ if length(proxy.nameserver_ips) > 0 ~}
    typed_dns_resolver_config:
      name: envoy.typed_dns_resolver_config
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.network.dns_resolver.cares.v3.CaresDnsResolverConfig
        resolvers:
%{ for nameserver_ip in proxy.nameserver_ips ~}
          - socket_address:
              address: ${nameserver_ip}
              port_value: 53
%{ endfor ~}
%{ endif ~}
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
                    address: ${nfs_server.domain}
                    port_value: ${nfs_server.port}
    transport_socket:
      name: envoy.transport_sockets.tls
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext
        common_tls_context:
          tls_certificates:
            - certificate_chain:
                filename: "/etc/nfs-tunnel/certs/client.crt"
              private_key:
                filename: "/etc/nfs-tunnel/certs/client.key"
          validation_context:
            trusted_ca:
              filename: "/etc/nfs-tunnel/certs/ca.crt"