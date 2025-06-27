#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies && minio_os_uid >= 0 ~}
users:   
  - name: minio
    system: True
    lock_passwd: True
    uid: ${minio_os_uid}
%{ endif ~}

write_files:
  #Ferio etcd Credentials
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
  #Ferio config and unit file
  - path: /etc/ferio/config.yml
    owner: root:root
    permissions: "0400"
    content: |
%{ if length(minio_services) > 0 ~}
      minio_services:
%{ for idx, service in minio_services ~}
        - name: ${service.name}
          tenant_name: ${service.tenant_name}
          env_path: ${service.env_path}
%{ endfor ~}
%{ endif ~}
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

runcmd:
%{ if install_dependencies ~}
  - wget https://github.com/Ferlab-Ste-Justine/ferio/releases/download/v0.4.0/ferio_0.4.0_linux_amd64.tar.gz -O /tmp/ferio_0.4.0_linux_amd64.tar.gz
  - mkdir -p /tmp/ferio
  - tar zxvf /tmp/ferio_0.4.0_linux_amd64.tar.gz -C /tmp/ferio
  - cp /tmp/ferio/ferio /usr/local/bin/ferio
  - rm -rf /tmp/ferio
  - rm -f /tmp/ferio_0.4.0_linux_amd64.tar.gz
%{ endif ~}
  - systemctl enable ferio
  - systemctl start ferio