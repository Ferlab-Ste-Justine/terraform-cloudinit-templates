#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies ~}
users:
  - name: alertmanager
    system: true
    lock_passwd: true
    sudo: "ALL= NOPASSWD: /bin/systemctl reload alertmanager.service"
%{ endif ~}

write_files:
%{ if !install_dependencies ~}
  - path: /etc/sudoers.d/alertmanager
    owner: root:root
    permissions: "0440"
    content: |
      alertmanager ALL= NOPASSWD: /bin/systemctl reload alertmanager.service
%{ endif ~}
  - path: /etc/alertmanager/tls/ca.crt
    owner: root:root
    permissions: "0440"
    content: |
      ${indent(6, alertmanager.tls.ca_cert)}
  - path: /etc/alertmanager/tls/server.crt
    owner: root:root
    permissions: "0440"
    content: |
      ${indent(6, alertmanager.tls.server_cert)}
  - path: /etc/alertmanager/tls/server.key
    owner: root:root
    permissions: "0440"
    content: |
      ${indent(6, alertmanager.tls.server_key)}
  - path: /etc/alertmanager/web.yml
    owner: root:root
    permissions: "0440"
    content: |
      tls_server_config:
        cert_file: /etc/alertmanager/tls/server.crt
        key_file: /etc/alertmanager/tls/server.key
%{ if alertmanager.basic_auth.username == "" ~}
        client_auth_type: RequireAndVerifyClientCert
        client_ca_file: /etc/alertmanager/tls/ca.crt
%{ else ~}
        client_auth_type: NoClientCert
      basic_auth_users:
        "${alertmanager.basic_auth.username}": "${alertmanager.basic_auth.hashed_password}"
%{ endif ~}
  - path: /etc/alertmanager/cluster.yml
    owner: root:root
    permissions: "0440"
    content: |
      tls_server_config:
        cert_file: /etc/alertmanager/tls/server.crt
        key_file: /etc/alertmanager/tls/server.key
        client_auth_type: RequireAndVerifyClientCert
        client_ca_file: /etc/alertmanager/tls/ca.crt
      tls_client_config:
        cert_file: /etc/alertmanager/tls/server.crt
        key_file: /etc/alertmanager/tls/server.key
        client_ca_file: /etc/alertmanager/tls/ca.crt
  - path: /etc/systemd/system/alertmanager.service
    owner: root:root
    permissions: "0440"
    content: |
      [Unit]
      Description="Alerting Service"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      User=alertmanager
      Group=alertmanager
      Type=simple
      Restart=always
      RestartSec=1
      ExecStart=/usr/local/bin/alertmanager \
          --config.file=/etc/alertmanager/configs/alertmanager.yml \
          --storage.path=/var/lib/alertmanager/data \
          --cluster.listen-address="0.0.0.0:9094" \
          --web.config.file=/etc/alertmanager/web.yml \
          --cluster.tls-config=/etc/alertmanager/cluster.yml \
%{ for peer in alertmanager.peers ~}
          --cluster.peer="${peer}:9094" \
%{ endfor ~}
          --web.external-url=${alertmanager.external_url} \
          --data.retention=${alertmanager.data_retention} 
      ExecReload=/bin/kill -HUP $MAINPID

      [Install]
      WantedBy=multi-user.target
  - path: /usr/local/bin/reload-alertmanager-configs
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/sh
      ALERTMANAGER_STATUS=$(systemctl is-active alertmanager.service)
      if [ $ALERTMANAGER_STATUS = "active" ]; then
        sudo systemctl reload alertmanager.service
      fi

%{ if install_dependencies ~}
packages:
  - curl
%{ endif ~}

runcmd:
  #Setup alertmanager service
%{ if install_dependencies ~}
  - curl -L https://github.com/prometheus/alertmanager/releases/download/v0.25.0/alertmanager-0.25.0.linux-amd64.tar.gz --output alertmanager.tar.gz
  - mkdir -p /tmp/alertmanager
  - tar zxvf alertmanager.tar.gz -C /tmp/alertmanager
  - cp /tmp/alertmanager/alertmanager-0.25.0.linux-amd64/alertmanager /usr/local/bin/alertmanager
  - cp /tmp/alertmanager/alertmanager-0.25.0.linux-amd64/amtool /usr/local/bin/amtool
  - rm -r /tmp/alertmanager
  - rm alertmanager.tar.gz
%{ endif ~}
  - mkdir -p /var/lib/alertmanager/data
  - chown -R alertmanager:alertmanager /var/lib/alertmanager
  - chown -R alertmanager:alertmanager /etc/alertmanager
  - systemctl enable alertmanager
  - systemctl start alertmanager