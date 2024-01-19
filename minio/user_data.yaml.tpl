#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies ~}
users:   
  - name: minio
    system: True
    lock_passwd: True
%{ endif ~}

write_files:
  #Minio tls Certificates
  - path: /etc/minio/tls/CAs/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, minio_server.tls.ca_cert)}
  - path: /etc/minio/tls/public.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, minio_server.tls.server_cert)}
  - path: /etc/minio/tls/private.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, minio_server.tls.server_key)}
  #Minio kes Certificates
%{ if kes.endpoint != "" ~}
  - path: /etc/minio/kes/tls/client.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, kes.tls.client_key)}
  - path: /etc/minio/kes/tls/client.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, kes.tls.client_cert)}
  - path: /etc/minio/kes/tls/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, kes.tls.ca_cert)}
%{ endif ~}
  #Ferio etcd Credentials
%{ if length(ferio.etcd.endpoints) > 0 ~}
  - path: /etc/ferio/etcd/tls/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, ferio.etcd.auth.ca_cert)}
%{ if ferio.etcd.auth.client_cert != "" ~}
  - path: /etc/ferio/etcd/tls/client.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, ferio.etcd.auth.client_key)}
  - path: /etc/ferio/etcd/tls/client.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, ferio.etcd.auth.client_cert)}
%{ else ~}
  - path: /etc/ferio/etcd/auth.yml
    owner: root:root
    permissions: "0400"
    content: |
      username: ${ferio.etcd.auth.username}
      password: ${ferio.etcd.auth.password}
%{ endif ~}
%{ endif ~}
  #minio systemd env configuration
  - path: /etc/minio/env
    owner: root:root
    permissions: "0444"
    content: |
%{ if volume_pools != "" ~}
      MINIO_VOLUMES=${volume_pools}
%{ endif ~}
      MINIO_OPTS="--address \":${minio_server.api_port}\" --console-address \":${minio_server.console_port}\" --certs-dir /etc/minio/tls"
      MINIO_ROOT_USER="${minio_server.auth.root_username}"
      MINIO_ROOT_PASSWORD="${minio_server.auth.root_password}"
%{ if minio_server.api_url != "" ~}
      MINIO_SERVER_URL="${minio_server.api_url}"
%{ endif ~}
%{ if minio_server.console_url != "" ~}
      MINIO_BROWSER_REDIRECT_URL="${minio_server.console_url}"
%{ endif ~}
%{ if kes.endpoint != "" ~}
      MINIO_KMS_KES_ENDPOINT=https://${kes.endpoint}
      MINIO_KMS_KES_CERT_FILE=/etc/minio/kes/tls/client.crt
      MINIO_KMS_KES_KEY_FILE=/etc/minio/kes/tls/client.key
      MINIO_KMS_KES_CAPATH=/etc/minio/kes/tls/ca.crt
      MINIO_KMS_KES_KEY_NAME=${kes.key}
%{ endif ~}
%{ if prometheus_auth_type != "" ~}
      MINIO_PROMETHEUS_AUTH_TYPE=${prometheus_auth_type}
%{ endif ~}
%{ if length(ferio.etcd.endpoints) > 0 ~}
  #Ferio config and unit file
  - path: /etc/ferio/config.yml
    owner: root:root
    permissions: "0400"
    content: |
      etcd:
        config_prefix: ${ferio.etcd.config_prefix}
        workspace_prefix: ${ferio.etcd.workspace_prefix}
%{ if ferio.host != "" ~}
        host: ${ferio.host}
%{ endif ~}
        endpoints:
%{ for idx, val in ferio.etcd.endpoints ~}
          - ${val}
%{ endfor ~}
        connection_timeout: ${ferio.etcd.connection_timeout}
        request_timeout: ${ferio.etcd.request_timeout}
        retry_interval: ${ferio.etcd.retry_interval}
        retries: ${ferio.etcd.retries}
        auth:
          ca_cert: /etc/ferio/etcd/tls/ca.crt
%{ if ferio.etcd.auth.client_cert != "" ~}
          client_cert: /etc/ferio/etcd/tls/client.crt
          client_key: /etc/ferio/etcd/tls/client.key
%{ else ~}
          password_auth: /etc/ferio/etcd/auth.yml
%{ endif ~}
      binaries_dir: /opt/minio/binaries
      log_level: ${ferio.log_level}
  - path: /etc/systemd/system/ferio.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Ferio Service"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      Environment=FERIO_CONFIG_FILE=/etc/ferio/config.yml
      User=root
      Group=root
      Type=simple
      Restart=always
      RestartSec=1
      ExecStart=/usr/local/bin/ferio

      [Install]
      WantedBy=multi-user.target
%{ else ~}
  #Minio unit file
  - path: /etc/systemd/system/minio.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Minio Service"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      EnvironmentFile=-/etc/minio/env
      User=minio
      Group=minio
      Type=simple
      Restart=always
      RestartSec=1
      ExecStart=/usr/local/bin/minio server $MINIO_OPTS

      [Install]
      WantedBy=multi-user.target
%{ endif ~}

runcmd:
  - chown -R minio:minio /etc/minio
  - chown -R minio:minio ${minio_server.volumes_root}
%{ if length(ferio.etcd.endpoints) > 0 ~}
%{ if install_dependencies ~}
  - wget https://github.com/Ferlab-Ste-Justine/ferio/releases/download/v0.1.0/ferio_0.1.0_linux_amd64.tar.gz -O /tmp/ferio_0.1.0_linux_amd64.tar.gz
  - mkdir -p /tmp/ferio
  - tar zxvf /tmp/ferio_0.1.0_linux_amd64.tar.gz -C /tmp/ferio
  - cp /tmp/ferio/ferio /usr/local/bin/ferio
  - rm -rf /tmp/ferio
  - rm -f /tmp/ferio_0.1.0_linux_amd64.tar.gz
%{ endif ~}
  - systemctl enable ferio
  - systemctl start ferio
%{ else ~}
%{ if install_dependencies ~}
  - wget ${minio_download_url} -O minio
  - mv minio /usr/local/bin/minio
  - chmod +x /usr/local/bin/minio
%{ endif ~}
  - systemctl enable minio
  - systemctl start minio
%{ endif ~}