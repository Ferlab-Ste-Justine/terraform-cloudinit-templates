#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if reverse_proxy.user.create ~}
users:
  - name: ${reverse_proxy.user.name}
    system: true
    lock_passwd: true
%{ endif ~}

write_files:
  #Tls Certs
%{ if reverse_proxy.tls != null ~}
  - path: /etc/http-security-reverse-proxy/certs/server.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, reverse_proxy.tls.server_cert)}
  - path: /etc/http-security-reverse-proxy/certs/server.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, reverse_proxy.tls.server_key)}
%{ if reverse_proxy.tls.ca_cert != null ~}
  - path: /etc/http-security-reverse-proxy/certs/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, reverse_proxy.tls.ca_cert)}
%{ endif ~}
%{ endif ~}
  #Envoy Config
  - path: /etc/http-security-reverse-proxy/envoy/core.yml
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, envoy_config_core)}
  - path: /etc/http-security-reverse-proxy/envoy/clusters.yml
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, envoy_config_clusters)}
  - path: /etc/http-security-reverse-proxy/envoy/listeners.yml
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, envoy_config_listeners)}
  #Systemd Service
  - path: /etc/systemd/system/http-security-reverse-proxy.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Reverse proxy to give restricted secure access to local http endpoints"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      User=${reverse_proxy.user.name}
      Group=${reverse_proxy.user.name}
      Type=simple
      Restart=always
      RestartSec=1
      # Ugly workaround for now: https://github.com/envoyproxy/envoy/issues/8297#issuecomment-620659781
      ExecStart=bash -c '/usr/local/bin/envoy --base-id 2 \
                                              --config-path "/etc/http-security-reverse-proxy/envoy/core.yml" \
                                              --concurrency 2 | tee'

      [Install]
      WantedBy=multi-user.target

runcmd:
%{ if install_dependencies ~}
  - wget -O /usr/local/bin/envoy https://github.com/envoyproxy/envoy/releases/download/v1.39.0/envoy-contrib-1.39.0-linux-${cpu_architecture}
  - chmod +x /usr/local/bin/envoy
%{ endif ~}
  - chown -R ${reverse_proxy.user.name}:${reverse_proxy.user.name} /etc/http-security-reverse-proxy
  - systemctl enable http-security-reverse-proxy
  - systemctl start http-security-reverse-proxy