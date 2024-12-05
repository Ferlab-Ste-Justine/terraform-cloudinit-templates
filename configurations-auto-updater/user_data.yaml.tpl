#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
%{ if vault_agent.etcd_auth.enabled ~}
%{ if etcd.auth.client_certificate != "" ~}
  - path: /etc/vault-agent.d/config/${naming.service}-etcd.hcl
    owner: root:root
    permissions: "0440"
    content: |
      template {
        source      = "/etc/${naming.service}/vault-agent/etcd/template.ctmpl"
        destination = "/etc/${naming.service}/vault-agent/etcd/client_cert_key.pem"
        exec        = "/etc/${naming.service}/vault-agent/etcd/reload.sh"
        perms       = "0600"
      }
  - path: /etc/${naming.service}/vault-agent/etcd/template.ctmpl
    owner: root:root
    permissions: "0440"
    content: |
      {{ with secret "${vault_agent.etcd_auth.secret_path}" }}
      {{ .Data.data.certificate }}
      {{ .Data.data.key }}
      {{ end }}
  - path: /etc/${naming.service}/vault-agent/etcd/reload.sh
    owner: root:root
    permissions: "0440"
    content: |
      #!/bin/sh
      set -xe

      cp /etc/${naming.service}/vault-agent/etcd/client_cert_key.pem /tmp/${naming.service}-client_cert_key.pem
      chown ${user}:${user} /tmp/${naming.service}-client_cert_key.pem
      mv /tmp/${naming.service}-client_cert_key.pem /etc/${naming.service}/etcd/client_cert_key.pem
      systemctl restart ${naming.service}.service
%{ else ~}
  - path: /etc/vault-agent.d/config/${naming.service}-etcd.hcl
    owner: root:root
    permissions: "0440"
    content: |
      template {
        source      = "/etc/${naming.service}/vault-agent/etcd/template.ctmpl"
        destination = "/etc/${naming.service}/vault-agent/etcd/password.yml"
        exec        = "/etc/${naming.service}/vault-agent/etcd/reload.sh"
        perms       = "0600"
      }
  - path: /etc/${naming.service}/vault-agent/etcd/template.ctmpl
    owner: root:root
    permissions: "0440"
    content: |
      {{ with secret "${vault_agent.etcd_auth.secret_path}" }}
      username: {{ .Data.data.username }}
      password: {{ .Data.data.password }}
      {{ end }}
  - path: /etc/${naming.service}/vault-agent/etcd/reload.sh
    owner: root:root
    permissions: "0550"
    content: |
      #!/bin/sh
      set -xe

      cp /etc/${naming.service}/vault-agent/etcd/password.yml /tmp/${naming.service}-password.yml
      chown ${user}:${user} /tmp/${naming.service}-password.yml
      mv /tmp/${naming.service}-password.yml /etc/${naming.service}/etcd/password.yml
      systemctl restart ${naming.service}.service
%{ endif ~}
%{ endif ~}
  - path: /etc/${naming.service}/config.yml
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, config)}
  - path: /etc/${naming.service}/etcd/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, etcd.auth.ca_certificate)}
%{ if etcd.auth.client_certificate != "" ~}
  - path: /etc/${naming.service}/etcd/client_cert_key.pem
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, etcd.auth.client_certificate)}
      ${indent(6, etcd.auth.client_key)}
%{ else ~}
  - path: /etc/${naming.service}/etcd/password.yml
    owner: root:root
    permissions: "0400"
    content: |
      username: ${etcd.auth.username}
      password: ${etcd.auth.password}
%{ endif ~}
%{ for idx, grpc_notification in grpc_notifications ~}
  - path: /etc/${naming.service}/grpc/endpoint${idx}/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, grpc_notification.auth.ca_cert)}
  - path: /etc/${naming.service}/grpc/endpoint${idx}/client.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, grpc_notification.auth.client_cert)}
  - path: /etc/${naming.service}/grpc/endpoint${idx}/client.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, grpc_notification.auth.client_key)}
%{ endfor ~}
  - path: /etc/systemd/system/${naming.service}.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Systemd ${naming.service} Service"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      Environment=CONFS_AUTO_UPDATER_CONFIG_FILE=/etc/${naming.service}/config.yml
      User=${user}
      Group=${user}
      Type=simple
      Restart=always
      RestartSec=1
      WorkingDirectory=${filesystem.path}
      ExecStart=/usr/local/bin/${naming.binary}

      [Install]
      WantedBy=multi-user.target

%{ if install_dependencies ~}
packages:
  - curl
%{ endif ~}

runcmd:
%{ if install_dependencies ~}
  #Install configurations-auto-updater
  - curl -L https://github.com/Ferlab-Ste-Justine/configurations-auto-updater/releases/download/v0.5.0/configurations-auto-updater_0.5.0_linux_amd64.tar.gz -o /tmp/configurations-auto-updater_0.5.0_linux_amd64.tar.gz
  - mkdir -p /tmp/configurations-auto-updater
  - tar zxvf /tmp/configurations-auto-updater_0.5.0_linux_amd64.tar.gz -C /tmp/configurations-auto-updater
  - cp /tmp/configurations-auto-updater/configurations-auto-updater /usr/local/bin/${naming.binary}
  - rm -rf /tmp/configurations-auto-updater
  - rm -f /tmp/configurations-auto-updater_0.5.0_linux_amd64.tar.gz
%{ endif ~}
  - mkdir -p ${filesystem.path}
  - chown -R ${user}:${user} ${filesystem.path}
  - chown -R ${user}:${user} /etc/${naming.service}
  - systemctl enable ${naming.service}
  - systemctl start ${naming.service}