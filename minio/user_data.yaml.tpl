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
%{ for srv_idx, minio_server in minio_servers ~}
%{ if minio_server.migrate_to  ~}
  - path: /opt/minio_migrate_to_tenant.sh
    owner: root:root
    permissions: "0500"
    content: |
      #!/usr/bin/env bash
      IGNORE=("${minio_server.tenant_name}" "." "..")

%{ for vol_root in volume_roots ~}
      cd ${vol_root}

      if [ ! -d "${minio_server.tenant_name}" ]; then
        mkdir ${minio_server.tenant_name}

        for FILE in $(ls -a); do
          if ! echo "$${IGNORE[@]}" | grep -q "$FILE"; then
            mv $FILE ${minio_server.tenant_name}/
          fi
        done
      else
        echo "Tenant ${minio_server.tenant_name} already exists. Aborting migration."
        exit
      fi
%{ endfor ~}
%{ endif ~}
  #Minio tls Certificates
%{ for idx, cert in minio_server.tls.ca_certs ~}
  - path: ${minio_server.config_path}/tls/CAs/ca${idx}.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, cert)}
%{ endfor ~}
  - path: ${minio_server.config_path}/tls/public.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, minio_server.tls.server_cert)}
  - path: ${minio_server.config_path}/tls/private.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, minio_server.tls.server_key)}
  #Minio kes Certificates
%{ if kes.endpoint != "" ~}
  - path: ${minio_server.config_path}/kes/tls/client.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, element(kes.clients, srv_idx).tls.client_key)}
  - path: ${minio_server.config_path}/kes/tls/client.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, element(kes.clients, srv_idx).tls.client_cert)}
  - path: ${minio_server.config_path}/kes/tls/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, kes.ca_cert)}
%{ endif ~}
  #minio systemd env configuration
  - path: ${minio_server.config_path}/env
    owner: root:root
    permissions: "0444"
    content: |
%{ if length(volume_pools) > 0 ~}
      MINIO_VOLUMES=${element(volume_pools, srv_idx)}
%{ endif ~}
      MINIO_OPTS="--address \":${minio_server.api_port}\" --console-address \":${minio_server.console_port}\" --certs-dir ${minio_server.config_path}/tls"
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
      MINIO_KMS_KES_CERT_FILE=${minio_server.config_path}/kes/tls/client.crt
      MINIO_KMS_KES_KEY_FILE=${minio_server.config_path}/kes/tls/client.key
      MINIO_KMS_KES_CAPATH=${minio_server.config_path}/kes/tls/ca.crt
      MINIO_KMS_KES_KEY_NAME=${element(kes.clients, srv_idx).key}
%{ endif ~}
%{ if prometheus_auth_type != "" ~}
      MINIO_PROMETHEUS_AUTH_TYPE=${prometheus_auth_type}
%{ endif ~}
%{ if godebug_settings != "" ~}
      GODEBUG=${godebug_settings}
%{ endif ~}
%{ if setup_minio_service ~}
  #Minio unit file
  - path: /etc/systemd/system/${minio_server.service_name}
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Minio Service"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      EnvironmentFile=-${minio_server.config_path}/env
      User=minio
      Group=minio
      Type=simple
      Restart=always
      RestartSec=1
      ExecStart=/usr/local/bin/minio server $MINIO_OPTS

      [Install]
      WantedBy=multi-user.target
%{ endif ~}
%{ endfor ~}

runcmd:
%{ for srv_idx, minio_server in minio_servers ~}
  - chown -R minio:minio ${minio_server.config_path}
%{ if minio_server.migrate_to  ~}
  - /opt/minio_migrate_to_tenant.sh
%{ endif ~}
%{ endfor ~}

%{ for vol_root in volume_roots ~}
  - chown minio:minio ${vol_root}
%{ endfor ~}

%{ if setup_minio_service ~}
%{ if install_dependencies ~}
  - wget ${minio_download_url} -O minio
  - mv minio /usr/local/bin/minio
  - chmod +x /usr/local/bin/minio
%{ endif ~}
%{ for srv_idx, minio_server in minio_servers ~}
  - systemctl enable ${minio_server.service_name}
  - systemctl start ${minio_server.service_name}
%{ endfor ~}
%{ endif ~}