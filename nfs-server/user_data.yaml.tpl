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
  - path: /etc/nfs-tunnel/certs/server.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, tls.server_cert)}
  - path: /etc/nfs-tunnel/certs/server.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, tls.server_key)}
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
  - path: /etc/systemd/system/nfs-tunnel-server.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Nfs Tunnel Server"
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
  #Nfs config file
  - path: /opt/nfs_exports
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, nfs_exports)}
  - path: /opt/generate_nfs_dirs.sh
    owner: root:root
    permissions: "0500"
    content: |
      #!/usr/bin/env sh
%{ for dir in nfs_dirs ~}
      mkdir -p ${dir}
%{ endfor ~}

%{ if install_dependencies ~}
packages:
  - nfs-kernel-server
  - iptables-persistent
%{ endif ~}

runcmd:
  #Prevent direct external access to portmapper and nfs
  - systemctl enable netfilter-persistent.service
  - systemctl start netfilter-persistent.service
  - iptables -A INPUT -p tcp -s localhost --dport 111 -j ACCEPT
  - iptables -A INPUT -p tcp --dport 111 -j DROP
  - iptables -A INPUT -p tcp -s localhost --dport 2049 -j ACCEPT
  - iptables -A INPUT -p tcp --dport 2049 -j DROP
  - iptables-save > /etc/iptables/rules.v4
  - ip6tables-save > /etc/iptables/rules.v6
  #Finalize nfs setup
  - /opt/generate_nfs_dirs.sh
  - cp /opt/nfs_exports /etc/exports
  - systemctl start nfs-kernel-server.service
  - systemctl enable nfs-kernel-server.service
  - exportfs -a
  #Setup envoy
%{ if install_dependencies ~}
  - wget -O /usr/local/bin/envoy https://github.com/envoyproxy/envoy/releases/download/v1.25.1/envoy-1.25.1-linux-x86_64
  - chmod +x /usr/local/bin/envoy
%{ endif ~}
  - chown -R nfs-tunnel:nfs-tunnel /etc/nfs-tunnel
  - systemctl enable nfs-tunnel-server
  - systemctl start nfs-tunnel-server