#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
#systemd-remote
  - path: /etc/systemd-remote/tls/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, server.tls.ca_certificate)}
  - path: /etc/systemd-remote/tls/service.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, server.tls.server_certificate)}
  - path: /etc/systemd-remote/tls/service.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, server.tls.server_key)}
  - path: /etc/systemd-remote/config.yml
    owner: root:root
    permissions: "0400"
    content: |
      units_config_path: /etc/systemd-remote/units.yml
      server:
        port: ${server.port}
        address: "${server.address}"
        tls:
          ca_cert: /etc/systemd-remote/tls/ca.crt
          server_cert: /etc/systemd-remote/tls/service.crt
          server_key: /etc/systemd-remote/tls/service.key
  - path: /etc/systemd/system/systemd-remote.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Systemd Remote Service"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      Environment=SYSTEMD_REMOTE_CONFIG_FILE=/etc/systemd-remote/config.yml
      User=root
      Group=root
      Type=simple
      Restart=always
      RestartSec=1
      ExecStart=/usr/local/bin/systemd-remote

      [Install]
      WantedBy=multi-user.target

%{ if install_dependencies ~}
packages:
  - curl
%{ endif ~}

runcmd:
%{ if install_dependencies ~}
  #Install systemd-remote
  - curl -L https://github.com/Ferlab-Ste-Justine/systemd-remote/releases/download/v0.2.0/systemd-remote_0.2.0_linux_amd64.tar.gz -o /tmp/systemd-remote_0.2.0_linux_amd64.tar.gz
  - mkdir -p /tmp/systemd-remote
  - tar zxvf /tmp/systemd-remote_0.2.0_linux_amd64.tar.gz -C /tmp/systemd-remote
  - cp /tmp/systemd-remote/systemd-remote /usr/local/bin/systemd-remote
  - rm -rf /tmp/systemd-remote
  - rm -f /tmp/systemd-remote_0.2.0_linux_amd64.tar.gz
%{ endif ~}
  - systemctl enable systemd-remote
  - systemctl start systemd-remote