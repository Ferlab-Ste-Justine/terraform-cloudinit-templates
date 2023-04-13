#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies ~}
users:
  - name: vault
    system: true
    lock_passwd: true
%{ endif ~}

write_files:
  - path: /opt/vault/vault-ca.crt
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, tls.ca_certificate)}
  - path: /opt/vault/vault-server.crt
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, tls.server_certificate)}
  - path: /opt/vault/vault-server.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, tls.server_key)}
  - path: /opt/vault/etcd-ca.crt
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, etcd_backend.ca_certificate)}
%{ if etcd_backend.client.username == "" ~}
  - path: /opt/vault/etcd-client.crt
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, etcd_backend.client.certificate)}
  - path: /opt/vault/etcd-client.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, etcd_backend.client.key)}
%{ endif ~}
  - path: /opt/vault/vault.hcl
    owner: root:root
    permissions: "0444"
    content: |
      ui           = true
      api_addr     = "https://${hostname}:8200"
      cluster_addr = "https://${hostname}:8201"

      listener "tcp" {
        address                            = "0.0.0.0:8200"
        tls_min_version                    = "tls13"
        tls_client_ca_file                 = "/opt/vault/vault-ca.crt"
        tls_cert_file                      = "/opt/vault/vault-server.crt"
        tls_key_file                       = "/opt/vault/vault-server.key"
%{ if tls.client_auth ~}
        tls_require_and_verify_client_cert = true
%{ endif ~}
      }

      storage "etcd" {
        ha_enabled    = true
        address       = "${etcd_backend.urls}"
        path          = "${etcd_backend.key_prefix}"
        tls_ca_file   = "/opt/vault/etcd-ca.crt"
%{ if etcd_backend.client.username == "" ~}
        tls_cert_file = "/opt/vault/etcd-client.crt"
        tls_key_file  = "/opt/vault/etcd-client.key"
%{ else ~}
        username      = "${etcd_backend.client.username}"
        password      = "${etcd_backend.client.password}"
%{ endif ~}
      }
  - path: /etc/systemd/system/vault.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="HashiCorp Vault - A tool for managing secrets"
      Documentation=https://www.vaultproject.io/docs/
      Requires=network-online.target
      After=network-online.target
      ConditionFileNotEmpty=/opt/vault/vault.hcl
      StartLimitIntervalSec=60
      StartLimitBurst=3

      [Service]
      User=vault
      Group=vault
      ProtectSystem=full
      ProtectHome=read-only
      PrivateTmp=yes
      PrivateDevices=yes
      SecureBits=keep-caps
      AmbientCapabilities=CAP_IPC_LOCK
      CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
      NoNewPrivileges=yes
      ExecStart=/usr/local/bin/vault server -config=/opt/vault/vault.hcl
      ExecReload=/bin/kill --signal HUP $MAINPID
      KillMode=process
      KillSignal=SIGINT
      Restart=on-failure
      RestartSec=5
      TimeoutStopSec=30
      StartLimitInterval=60
      StartLimitBurst=3
      LimitNOFILE=65536
      LimitMEMLOCK=infinity

      [Install]
      WantedBy=multi-user.target

%{ if install_dependencies ~}
packages:
  - unzip
%{ endif ~}

runcmd:
%{ if install_dependencies ~}
  #Vault Installation
  - curl -O https://releases.hashicorp.com/vault/${release_version}/vault_${release_version}_linux_amd64.zip
  - unzip vault_${release_version}_linux_amd64.zip
  - mv vault /usr/local/bin/
%{ endif ~}
  #Vault Service
  - chown -R vault:vault /opt/vault
  - systemctl enable vault
  - systemctl start vault