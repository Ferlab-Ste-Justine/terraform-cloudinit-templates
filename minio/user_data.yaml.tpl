#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies && minio_os_uid >= 0  ~}
users:   
  - name: minio
    system: True
    lock_passwd: True
    uid: ${minio_os_uid}
%{ endif ~}

write_files:
  #Minio tls Certificates
%{ for idx, cert in minio_server.tls.ca_certs ~}
  - path: /etc/minio/tls/CAs/ca${idx}.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, cert)}
%{ endfor ~}
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
%{ if godebug_settings != "" ~}
      GODEBUG=${godebug_settings}
%{ endif ~}
%{ if setup_minio_service ~}
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
%{ for vol_root in minio_server.volumes_roots ~}
  - chown minio:minio ${vol_root}
%{ endfor ~}

%{ if setup_minio_service ~}
%{ if install_dependencies ~}
  - wget ${minio_download_url} -O minio
  - mv minio /usr/local/bin/minio
  - chmod +x /usr/local/bin/minio
%{ endif ~}
  - systemctl enable minio
  - systemctl start minio
%{ endif ~}