#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies ~}
users:
  - name: nfs-tunnel
    system: true
    lock_passwd: true
%{ endif ~}

write_files:
  #Tls Certs
  - path: /etc/nfs-tunnel/certs/client.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, tls.client_cert)}
  - path: /etc/nfs-tunnel/certs/client.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, tls.client_key)}
  - path: /etc/nfs-tunnel/certs/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, tls.ca_cert)}
  #Envoy Config
  - path: /etc/nfs-tunnel/envoy/core.yml
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, envoy_config_core)}
  - path: /etc/nfs-tunnel/envoy/clusters.yml
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, envoy_config_clusters)}
  - path: /etc/nfs-tunnel/envoy/listeners.yml
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, envoy_config_listeners)}
  #Systemd Service
  - path: /etc/systemd/system/nfs-tunnel-client.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Nfs Tunnel Client"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      User=nfs-tunnel
      Group=nfs-tunnel
      Type=simple
      Restart=always
      RestartSec=1
      # Ugly workaround for now: https://github.com/envoyproxy/envoy/issues/8297#issuecomment-620659781
      ExecStart=bash -c '/usr/local/bin/envoy --base-id 2 \
                                              --config-path "/etc/nfs-tunnel/envoy/core.yml" \
                                              --concurrency 2 | tee'

      [Install]
      WantedBy=multi-user.target

%{ if install_dependencies ~}
packages:
  - nfs-common
%{ endif ~}

runcmd:
  #Protect portmapper port
  - iptables -A INPUT -p tcp -s localhost --dport 111 -j ACCEPT
  - iptables -A INPUT -p tcp --dport 111 -j DROP
  #Setup envoy
%{ if install_dependencies ~}
  - wget -O /usr/local/bin/envoy https://github.com/envoyproxy/envoy/releases/download/v1.25.1/envoy-1.25.1-linux-x86_64
  - chmod +x /usr/local/bin/envoy
%{ endif ~}
  - chown -R nfs-tunnel:nfs-tunnel /etc/nfs-tunnel
  - systemctl enable nfs-tunnel-client
  - systemctl start nfs-tunnel-client
