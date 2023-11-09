#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies ~}
users:
  - name: pushgateway
    system: true
    lock_passwd: true
%{ endif ~}

write_files:
  - path: /etc/pushgateway/tls/ca.crt
    owner: root:root
    permissions: "0440"
    content: |
      ${indent(6, pushgateway.tls.ca_cert)}
  - path: /etc/pushgateway/tls/server.crt
    owner: root:root
    permissions: "0440"
    content: |
      ${indent(6, pushgateway.tls.server_cert)}
  - path: /etc/pushgateway/tls/server.key
    owner: root:root
    permissions: "0440"
    content: |
      ${indent(6, pushgateway.tls.server_key)}
  - path: /etc/pushgateway/config.yml
    owner: root:root
    permissions: "0440"
    content: |
      tls_server_config:
        cert_file: /etc/pushgateway/tls/server.crt
        key_file: /etc/pushgateway/tls/server.key
%{ if pushgateway.basic_auth.username == "" ~}
        client_auth_type: RequireAndVerifyClientCert
        client_ca_file: /etc/pushgateway/tls/ca.crt
%{ else ~}
        client_auth_type: NoClientCert
      basic_auth_users:
        "${pushgateway.basic_auth.username}": "${pushgateway.basic_auth.hashed_password}"
%{ endif ~}
  - path: /etc/systemd/system/pushgateway.service
    owner: root:root
    permissions: "0440"
    content: |
      [Unit]
      Description="Metrics Push Service"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      User=pushgateway
      Group=pushgateway
      Type=simple
      Restart=always
      RestartSec=1
      ExecStart=/usr/local/bin/pushgateway \
          --persistence.file=/var/lib/pushgateway/data/state \
          --web.listen-address=0.0.0.0:9091 \
          --web.config.file=/etc/pushgateway/config.yml
      ExecReload=/bin/kill -HUP $MAINPID

      [Install]
      WantedBy=multi-user.target

%{ if install_dependencies ~}
packages:
  - curl
%{ endif ~}

runcmd:
  #Setup alertmanager service
%{ if install_dependencies ~}
  - curl -L https://github.com/prometheus/pushgateway/releases/download/v1.6.2/pushgateway-1.6.2.linux-amd64.tar.gz --output pushgateway.tar.gz
  - mkdir -p /tmp/pushgateway
  - tar zxvf pushgateway.tar.gz -C /tmp/pushgateway
  - cp /tmp/pushgateway/pushgateway-1.6.2.linux-amd64/pushgateway /usr/local/bin/pushgateway
  - rm -r /tmp/pushgateway
  - rm pushgateway.tar.gz
%{ endif ~}
  - mkdir -p /var/lib/pushgateway/data
  - chown -R pushgateway:pushgateway /var/lib/pushgateway
  - chown -R pushgateway:pushgateway /etc/pushgateway
  - systemctl enable pushgateway
  - systemctl start pushgateway