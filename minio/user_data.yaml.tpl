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
  #minio systemd configuration
  - path: /etc/minio/env
    owner: root:root
    permissions: "0444"
    content: |
      MINIO_VOLUMES=${volume_pools}
      MINIO_OPTS="--address= :${minio_server.api_port} --console-address :${minio_server.console_port}"
      MINIO_ROOT_USER="${minio_server.auth.root_username}"
      MINIO_ROOT_PASSWORD="${minio_server.auth.root_password}"
%{ if minio_server.load_balancer_url != "" ~}
      MINIO_SERVER_URL="${minio_server.load_balancer_url}"
%{ endif ~}
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
      ExecStart=/usr/local/bin/minio server --certs-dir /etc/minio/tls

      [Install]
      WantedBy=multi-user.target

runcmd:
%{ if install_dependencies ~}
  - wget https://dl.min.io/server/minio/release/linux-amd64/minio_20230609073212.0.0_amd64.deb
  - dpkg -i minio_20230609073212.0.0_amd64.deb
  - rm minio_20230609073212.0.0_amd64.deb
%{ endif ~}
  - chown -R minio:minio /etc/minio
  - chown -R minio:minio ${minio_server.volumes_root}
  - systemctl enable minio
  - systemctl start minio