resources:
  - "@type": type.googleapis.com/envoy.config.listener.v3.Listener
    name: http_secutiry_reverse_proxy_listener
    address:
      socket_address:
        protocol: TCP
        address: ${reverse_proxy.ip}
        port_value: ${reverse_proxy.port}
    filter_chains:
      - filters:
          - name: envoy.filters.network.connection_limit
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.network.connection_limit.v3.ConnectionLimit
              stat_prefix: http_secutiry_reverse_proxy_listener_connection_limit
              max_connections: ${reverse_proxy.max_connections}
          - name: envoy.filters.network.http_connection_manager
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
              codec_type: AUTO
              stat_prefix: ingress_http
              route_config:
                name: backends
                virtual_hosts:
                - name: backends
                  domains:
                    - "*"
                  routes:
%{ for idx, backend in reverse_proxy.backends ~}
%{ for path_mapping in backend.path_mappings ~}
                    - match:
                        prefix: "${path_mapping.frontend_path}"
                      route:
                        cluster: http_secutiry_reverse_proxy_cluster_${idx}
%{ if path_mapping.backend_path != null ~}
                        prefix_rewrite: "${path_mapping.backend_path}"
%{ endif ~}
%{ endfor ~}
%{ endfor ~}
              http_filters:
                - name: envoy.filters.http.router
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
%{ if reverse_proxy.tls != null ~}
        transport_socket:
          name: envoy.transport_sockets.tls
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
            require_client_certificate: true
            common_tls_context:
              tls_certificates:
                - certificate_chain:
                    filename: /etc/http-security-reverse-proxy/certs/server.crt
                  private_key:
                    filename: /etc/http-security-reverse-proxy/certs/server.key
%{ if reverse_proxy.tls.ca_cert != null ~}
              validation_context:
                trusted_ca:
                  filename: /etc/http-security-reverse-proxy/certs/ca.crt
%{ endif ~}
%{ endif ~}