resources:
  - "@type": type.googleapis.com/envoy.config.listener.v3.Listener
    name: nfs_listener
    address:
      socket_address:
        protocol: TCP
        address: 127.0.0.1
        port_value: 2049
    filter_chains:
      - filters:
          - name: envoy.filters.network.connection_limit
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.network.connection_limit.v3.ConnectionLimit
              stat_prefix: nfs_listener_connection_limit
              max_connections: ${proxy.max_connections} 
          - name: envoy.filters.network.tcp_proxy
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
              stat_prefix: nfs_listener_tcp_proxy
              cluster: nfs_server
              idle_timeout: "${proxy.idle_timeout}"
              access_log:
                - name: envoy.access_loggers.stdout
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog