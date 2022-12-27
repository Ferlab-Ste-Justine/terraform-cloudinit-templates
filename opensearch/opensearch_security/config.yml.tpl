_meta:
  type: "config"
  config_version: 2

config:
  dynamic:
    http:
      anonymous_auth_enabled: false
      xff:
        enabled: false
    authc:
      clientcert_auth_domain:
        description: "Authenticate via TLS client certificates"
        http_enabled: true
        transport_enabled: true
        order: 1
        http_authenticator:
          type: clientcert
          config:
            username_attribute: cn
          challenge: false
        authentication_backend:
          type: noop
%{ if opensearch_cluster.basic_auth_enabled ~}
      basic_auth_domain:
        description: "Authenticate via username and password"
        http_enabled: true
        transport_enabled: false
        order: 2
        http_authenticator:
          type: basic
          challenge: true
        authentication_backend:
          type: intern
%{ endif ~}