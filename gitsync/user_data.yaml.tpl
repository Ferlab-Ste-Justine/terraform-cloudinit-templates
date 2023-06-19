#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
  - path: /etc/${naming.service}/config.yml
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, config)}
  - path: /etc/${naming.service}/git/auth/client_ssh_key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, git.auth.client_ssh_key)}
  - path: /etc/${naming.service}/git/auth/server_ssh_fingerprint
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, git.auth.server_ssh_fingerprint)}
%{ for idx, trusted_gpg_key in git.trusted_gpg_keys ~}
  - path: /etc/${naming.service}/git/trusted_gpg_keys/key{idx}.asc
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, trusted_gpg_key)}
%{ endfor ~}
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
  - path: /etc/systemd/system/${naming.service}.timer
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Run ${naming.service} recurrently"
      Requires=${naming.service}.service

      [Timer]
      Unit=${naming.service}.service
      OnCalendar=${timer_calendar}

      [Install]
      WantedBy=timers.target
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
      Environment=GITSYNC_CONFIG_FILE=/etc/${naming.service}/config.yml
      User=${user}
      Group=${user}
      Type=simple
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
  #Install gitsync
  - curl -L https://github.com/Ferlab-Ste-Justine/gitsync/releases/download/v0.1.0/gitsync_0.1.0_linux_amd64.tar.gz -o /tmp/gitsync_0.1.0_linux_amd64.tar.gz
  - mkdir -p /tmp/gitsync
  - tar zxvf /tmp/gitsync_0.1.0_linux_amd64.tar.gz -C /tmp/gitsync
  - cp /tmp/gitsync/gitsync /usr/local/bin/${naming.binary}
  - rm -rf /tmp/gitsync
  - rm -f /tmp/gitsync_0.1.0_linux_amd64.tar.gz
%{ endif ~}
  - mkdir -p ${filesystem.path}
  - chown -R ${user}:${user} ${filesystem.path}
  - chown -R ${user}:${user} /etc/${naming.service}
  - systemctl enable ${naming.service}.timer
  - systemctl start ${naming.service}.timer