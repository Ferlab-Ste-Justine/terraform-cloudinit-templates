#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies && minio_os_uid >= 0 ~}
users:
  - name: minio
    system: true
    lock_passwd: true
    uid: ${minio_os_uid}
%{ endif ~}

write_files:
%{ for srv_idx, s in minio_servers ~}
%{ if s.migrate_to ~}
  - path: /opt/minio_migrate_to_tenant.sh
    owner: root:root
    permissions: "0500"
    content: |
      #!/usr/bin/env bash
      set -euo pipefail
      IGNORE=("${s.tenant_name}" "." "..")
%{ for vol_root in volume_roots ~}
      cd ${vol_root}
      if [ ! -d "${s.tenant_name}" ]; then
        mkdir "${s.tenant_name}"
        chown minio:minio "${s.tenant_name}"
        for FILE in $(ls -A); do
          if ! echo "$${IGNORE[@]}" | grep -q "$FILE"; then
            mv "$FILE" "${s.tenant_name}/"
          fi
        done
      else
        echo "Tenant ${s.tenant_name} already exists. Aborting migration."
        exit 0
      fi
%{ endfor ~}
%{ endif ~}

%{ for idx, cert in s.tls.ca_certs ~}
  - path: ${s.config_path}/tls/CAs/ca${idx}.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, cert)}
%{ endfor ~}

  - path: ${s.config_path}/tls/public.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, s.tls.server_cert)}
  - path: ${s.config_path}/tls/private.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, s.tls.server_key)}

%{ if kes.endpoint != "" ~}
  - path: ${s.config_path}/kes/tls/client.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, element(kes.clients, srv_idx).tls.client_key)}
  - path: ${s.config_path}/kes/tls/client.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, element(kes.clients, srv_idx).tls.client_cert)}
  - path: ${s.config_path}/kes/tls/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, kes.ca_cert)}
%{ endif ~}

%{ if try(s.audit.client_cert, "") != "" && try(s.audit.client_key, "") != "" ~}
  - path: ${s.config_path}/audit/tls/client.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, s.audit.client_cert)}
  - path: ${s.config_path}/audit/tls/client.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, s.audit.client_key)}
%{ endif ~}

  - path: ${s.config_path}/env
    owner: root:root
    permissions: "0444"
    content: |
%{ if length(volume_pools) > 0 ~}
      MINIO_VOLUMES=${element(volume_pools, srv_idx)}
%{ endif ~}
      MINIO_OPTS="--address \":${s.api_port}\" --console-address \":${s.console_port}\" --certs-dir ${s.config_path}/tls"
      MINIO_ROOT_USER="${s.auth.root_username}"
      MINIO_ROOT_PASSWORD="${s.auth.root_password}"
%{ if s.api_url != "" ~}
      MINIO_SERVER_URL="${s.api_url}"
%{ endif ~}
%{ if s.console_url != "" ~}
      MINIO_BROWSER_REDIRECT_URL="${s.console_url}"
%{ endif ~}
%{ if kes.endpoint != "" ~}
      MINIO_KMS_KES_ENDPOINT="https://${kes.endpoint}"
      MINIO_KMS_KES_CERT_FILE="${s.config_path}/kes/tls/client.crt"
      MINIO_KMS_KES_KEY_FILE="${s.config_path}/kes/tls/client.key"
      MINIO_KMS_KES_CAPATH="${s.config_path}/kes/tls/ca.crt"
      MINIO_KMS_KES_KEY_NAME="${element(kes.clients, srv_idx).key}"
%{ endif ~}
%{ if prometheus_auth_type != "" ~}
      MINIO_PROMETHEUS_AUTH_TYPE="${prometheus_auth_type}"
%{ endif ~}
%{ if godebug_settings != "" ~}
      GODEBUG="${godebug_settings}"
%{ endif ~}

%{ if try(s.audit.enable, false) ~}
      MINIO_AUDIT_WEBHOOK_ENABLE_${s.audit.audit_id}="on"
      MINIO_AUDIT_WEBHOOK_ENDPOINT_${s.audit.audit_id}="${s.audit.endpoint}"
%{ if try(s.audit.auth_token, "") != "" ~}
      MINIO_AUDIT_WEBHOOK_AUTH_TOKEN_${s.audit.audit_id}="${s.audit.auth_token}"
%{ endif ~}
%{ if try(s.audit.queue_dir, "") != "" ~}
      MINIO_AUDIT_WEBHOOK_QUEUE_DIR_${s.audit.audit_id}="${s.audit.queue_dir}"
%{ endif ~}
%{ if try(s.audit.queue_size, "") != "" ~}
      MINIO_AUDIT_WEBHOOK_QUEUE_LIMIT_${s.audit.audit_id}="${s.audit.queue_size}"
%{ endif ~}
%{ if try(s.audit.client_cert, "") != "" && try(s.audit.client_key, "") != "" ~}
      MINIO_AUDIT_WEBHOOK_CLIENT_CERT_${s.audit.audit_id}="${s.config_path}/audit/tls/client.crt"
      MINIO_AUDIT_WEBHOOK_CLIENT_KEY_${s.audit.audit_id}="${s.config_path}/audit/tls/client.key"
%{ endif ~}
%{ endif ~}

%{ if setup_minio_service ~}
  - path: /etc/systemd/system/${s.service_name}
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description=MinIO Service
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      EnvironmentFile=-${s.config_path}/env
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
%{ for srv_idx, s in minio_servers ~}
  - chown -R minio:minio ${s.config_path}
%{ if s.migrate_to ~}
  - /opt/minio_migrate_to_tenant.sh
%{ endif ~}
%{ endfor ~}
%{ for vol_root in volume_roots ~}
  - chown minio:minio ${vol_root}
%{ endfor ~}

%{ for srv_idx, s in minio_servers ~}
%{ if try(s.audit.enable, false) && try(s.audit.queue_dir, "") != "" ~}
  - mkdir -p ${s.audit.queue_dir}
  - chown -R minio:minio ${s.audit.queue_dir}
%{ endif ~}
%{ endfor ~}

%{ if setup_minio_service ~}
%{ if install_dependencies ~}
  - wget ${minio_download_url} -O /usr/local/bin/minio
  - chmod +x /usr/local/bin/minio
%{ endif ~}
%{ for srv_idx, s in minio_servers ~}
  - systemctl enable ${s.service_name}
  - systemctl start ${s.service_name}
%{ endfor ~}
%{ endif ~}
