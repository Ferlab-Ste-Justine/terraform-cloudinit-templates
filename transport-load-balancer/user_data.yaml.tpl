#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies ~}
users:   
  - name: transport-load-balancer
    system: True
    lock_passwd: True
  - name: transport-control-plane
    system: True
    lock_passwd: True
%{ endif ~}

write_files:
  - path: /etc/transport-load-balancer/config.yml
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, load_balancer_config)}
  - path: /etc/transport-control-plane/config.yml
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, control_plane_config)}
  - path: /etc/transport-control-plane/etcd/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, control_plane.etcd.ca_certificate)}
%{ if control_plane.etcd.client.username == "" ~}
  - path: /etc/transport-control-plane/etcd/client.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, control_plane.etcd.client.certificate)}
  - path: /etc/transport-control-plane/etcd/client.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, control_plane.etcd.client.key)}
%{ else ~}
  - path: /etc/transport-control-plane/etcd/auth.yml
    owner: root:root
    permissions: "0400"
    content: |
      username: "${control_plane.etcd.client.username}"
      password: "${control_plane.etcd.client.password}"
%{ endif ~}
  #Transport control plane systemd configuration
  - path: /etc/systemd/system/transport-control-plane.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Transport Control Plane Service"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      User=transport-control-plane
      Group=transport-control-plane
      Type=simple
      Restart=always
      RestartSec=1
      Environment=ENVOY_TCP_CONFIG_FILE=/etc/transport-control-plane/config.yml
      # Ugly workaround for now: https://github.com/envoyproxy/envoy/issues/8297#issuecomment-620659781
      ExecStart=bash -c '/usr/local/bin/envoy-transport-control-plane'

      [Install]
      WantedBy=multi-user.target
  #Transport load balancer systemd configuration
  - path: /etc/systemd/system/transport-load-balancer.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Transport Load Balancer Service"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      User=transport-load-balancer
      Group=transport-load-balancer
      Type=simple
      Restart=always
      RestartSec=1
      # Ugly workaround for now: https://github.com/envoyproxy/envoy/issues/8297#issuecomment-620659781
      ExecStart=bash -c '/usr/local/bin/envoy --base-id 2 \
                                              --config-path "/etc/transport-load-balancer/config.yml" \
                                              --concurrency 2 | tee'

      [Install]
      WantedBy=multi-user.target

runcmd:
  #Setup control plane
%{ if install_dependencies ~}
  - wget -O /tmp/envoy-transport-control-plane_0.3.0_linux_amd64.tar.gz https://github.com/Ferlab-Ste-Justine/envoy-transport-control-plane/releases/download/v0.3.0/envoy-transport-control-plane_0.3.0_linux_amd64.tar.gz
  - mkdir -p /tmp/envoy-transport-control-plane
  - tar zxvf /tmp/envoy-transport-control-plane_0.3.0_linux_amd64.tar.gz -C /tmp/envoy-transport-control-plane
  - cp /tmp/envoy-transport-control-plane/envoy-transport-control-plane /usr/local/bin/envoy-transport-control-plane
  - rm -rf /tmp/envoy-transport-control-plane
  - rm -f /tmp/envoy-transport-control-plane_0.3.0_linux_amd64.tar.gz
  - chmod +x /usr/local/bin/envoy-transport-control-plane
%{ endif ~}
  - chown -R transport-control-plane:transport-control-plane /etc/transport-control-plane
  - systemctl enable transport-control-plane
  - systemctl start transport-control-plane
  #Setup envoy
%{ if install_dependencies ~}
  - wget -O /usr/local/bin/envoy https://github.com/envoyproxy/envoy/releases/download/v1.33.0/envoy-1.33.0-linux-x86_64
  - chmod +x /usr/local/bin/envoy
%{ endif ~}
  - chown -R transport-load-balancer:transport-load-balancer /etc/transport-load-balancer
  - setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/envoy
  - systemctl enable transport-load-balancer
  - systemctl start transport-load-balancer