#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies ~}
users:   
  - name: kes
    system: True
    lock_passwd: True
%{ endif ~}

write_files:
  #kes tls Certificates
  - path: /etc/kes/certs/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, kes_server.tls.ca_cert)}
  - path: /etc/kes/certs/server.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, kes_server.tls.server_cert)}
  - path: /etc/kes/certs/server.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, kes_server.tls.server_key)}
%{ if keystore.vault.ca_cert != "" ~}
  - path: /etc/kes/certs/vault/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, keystore.vault.ca_cert)}
%{ endif ~}
  - path: /etc/kes/config.yml
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, kes_config)}
  - path: /etc/kes/config.yml
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, kes_config)}
%{ for client in kes_server.clients ~}
  - path: /etc/kes/clients/${client.name}_client.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, client.client_cert)}
%{ endfor ~}
  - path: /etc/kes/clients/insert_identities.sh
    owner: root:root
    permissions: "0500"
    content: |
%{ for client in kes_server.clients ~}
      IDENTITY=$(kes identity of /etc/kes/clients/${client.name}_client.crt | tail -n 1)
      sed -i "s/{{client_${client.name}_identity}}/$IDENTITY/g" /etc/kes/config.yml
%{ endfor ~}
  #kes systemd configuration
  - path: /etc/systemd/system/kes.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="KES Service"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      LimitNOFILE=65535
      TasksMax=infinity
      AmbientCapabilities=CAP_IPC_LOCK
      User=kes
      Group=kes
      Type=simple
      Restart=always
      RestartSec=1
      TimeoutStopSec=infinity
      SendSIGKILL=no
      ExecStart=/usr/local/bin/kes server --config=/etc/kes/config.yml

      [Install]
      WantedBy=multi-user.target

runcmd:
%{ if install_dependencies ~}
  - wget https://github.com/minio/kes/releases/download/2023-11-10T10-44-28Z/kes-linux-amd64
  - mv kes-linux-amd64 /usr/local/bin/kes
  - chmod +x /usr/local/bin/kes
%{ endif ~}
  - /etc/kes/clients/insert_identities.sh
  - chown -R kes:kes /etc/kes
  - systemctl enable kes
  - systemctl start kes