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
      WorkingDirectory=${sync_directory}
      ExecStart=/usr/local/bin/systemd-remote

      [Install]
      WantedBy=multi-user.target
#systemd-remote-source
  - path: /etc/systemd-remote-source/tls/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, client.tls.ca_certificate)}
  - path: /etc/systemd-remote-source/tls/client.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, client.tls.client_certificate)}
  - path: /etc/systemd-remote-source/tls/client.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, client.tls.client_key)}
  - path: /etc/systemd-remote-source/etcd/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, client.etcd.ca_certificate)}
%{ if client.etcd.client.certificate != "" ~}
  - path: /etc/systemd-remote-source/etcd/client.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, client.etcd.client.certificate)}
  - path: /etc/systemd-remote-source/etcd/client.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, client.etcd.client.key)}
%{ else ~}
  - path: /etc/systemd-remote-source/etcd/password.yml
    owner: root:root
    permissions: "0400"
    content: |
      username: ${client.etcd.client.username}
      password: ${client.etcd.client.password}
%{ endif ~}
  - path: /etc/systemd-remote-source/config.yml
    owner: root:root
    permissions: "0400"
    content: |
      filesystem:
        path: "${sync_directory}"
        files_permission: "700"
        directories_permission: "700"
      etcd_client:
        prefix: "${client.etcd.key_prefix}"
        endpoints:
%{ for endpoint in client.etcd.endpoints ~}
          - "${endpoint}"
%{ endfor ~}
        connection_timeout: "60s"
        request_timeout: "60s"
        retry_interval: "4s"
        retries: 15
        auth:
          ca_cert: "/etc/systemd-remote-source/etcd/ca.crt"
%{ if client.etcd.client.certificate != "" ~}
          client_cert: "/etc/systemd-remote-source/etcd/client.crt"
          client_key: "/etc/systemd-remote-source/etcd/client.key"
%{ else ~}
          password_auth: /etc/systemd-remote-source/etcd/password.yml
%{ endif ~}
      grpc_notifications:
        - endpoint: "${server.address}:${server.port}"
          filter: "^(.*[.]service)|(.*[.]timer)|(units.yml)$"
          trim_key_path: true
          max_chunk_size: 1048576
          connection_timeout: "60s"
          request_timeout: "60s"
          retry_interval: "4s"
          retries: 15
          auth:
            ca_cert: "/etc/systemd-remote-source/tls/ca.crt"
            client_cert: "/etc/systemd-remote-source/tls/service.crt"
            client_key: "/etc/systemd-remote-source/tls/service.key"
  - path: /etc/systemd/system/systemd-remote-source.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Systemd Remote Source Service"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      Environment=CONFS_AUTO_UPDATER_CONFIG_FILE=/etc/systemd-remote-source/config.yml
      User=root
      Group=root
      Type=simple
      Restart=always
      RestartSec=1
      WorkingDirectory=${sync_directory}
      ExecStart=/usr/local/bin/systemd-remote-source

      [Install]
      WantedBy=multi-user.target

%{ if install_dependencies ~}
packages:
  - curl
  - unzip
%{ endif ~}

runcmd:
%{ if install_dependencies ~}
  #Install systemd-remote-source
  - curl -L https://github.com/Ferlab-Ste-Justine/configurations-auto-updater/releases/download/v0.4.0/configurations-auto-updater_0.4.0_linux_amd64.tar.gz -o /tmp/configurations-auto-updater_0.4.0_linux_amd64.tar.gz
  - mkdir -p /tmp/configurations-auto-updater
  - tar zxvf /tmp/configurations-auto-updater_0.4.0_linux_amd64.tar.gz -C /tmp/configurations-auto-updater
  - cp /tmp/configurations-auto-updater/configurations-auto-updater /usr/local/bin/systemd-remote-source
  - rm -rf /tmp/configurations-auto-updater
  - rm -f /tmp/configurations-auto-updater_0.4.0_linux_amd64.tar.gz
  #Install systemd-remote
  - curl -L https://github.com/Ferlab-Ste-Justine/systemd-remote/releases/download/v0.1.0/systemd-remote_0.1.0_linux_amd64.tar.gz -o /tmp/systemd-remote_0.1.0_linux_amd64.tar.gz
  - mkdir -p /tmp/systemd-remote
  - tar zxvf /tmp/systemd-remote_0.1.0_linux_amd64.tar.gz -C /tmp/systemd-remote
  - cp /tmp/systemd-remote/systemd-remote /usr/local/bin/systemd-remote
  - rm -rf /tmp/systemd-remote
  - rm -f /tmp/systemd-remote_0.1.0_linux_amd64.tar.gz
%{ endif ~}
  - mkdir -p ${sync_directory}
  - systemctl enable systemd-remote-source
  - systemctl start systemd-remote-source
  - systemctl enable systemd-remote
  - systemctl start systemd-remote