#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
  - path: /etc/terraform-backend-etcd/terraform/backend-vars
    owner: root:root
    permissions: "0400"
    content: |
      TF_HTTP_USERNAME=${server.auth.username}
      TF_HTTP_PASSWORD=${server.auth.password}
      TF_HTTP_UPDATE_METHOD=PUT
      TF_HTTP_LOCK_METHOD=PUT
      TF_HTTP_UNLOCK_METHOD=DELETE
  - path: /etc/terraform-backend-etcd/etcd/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, etcd.ca_certificate)}
%{ if etcd.client.certificate != "" ~}
  - path: /etc/terraform-backend-etcd/etcd/client.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, etcd.client.certificate)}
  - path: /etc/terraform-backend-etcd/etcd/client.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, etcd.client.key)}
%{ else ~}
  - path: /etc/terraform-backend-etcd/etcd/password.yml
    owner: root:root
    permissions: "0400"
    content: |
      username: ${etcd.client.username}
      password: ${etcd.client.password}
%{ endif ~}
  - path: /etc/terraform-backend-etcd/tls/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, server.tls.ca_certificate)}
  - path: /etc/terraform-backend-etcd/tls/server.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, server.tls.server_certificate)}
  - path: /etc/terraform-backend-etcd/tls/server.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, server.tls.server_key)}
  - path: /etc/terraform-backend-etcd/auth.yml
    owner: root:root
    permissions: "0400"
    content: |
      ${server.auth.username}: "${server.auth.password}"
  - path: /etc/terraform-backend-etcd/config.yml
    owner: root:root
    permissions: "0400"
    content: |
      server:
        port: ${server.port}
        address: "${server.address}"
        basic_auth: /etc/terraform-backend-etcd/auth.yml
        tls:
          certificate: /etc/terraform-backend-etcd/tls/server.crt
          key: /etc/terraform-backend-etcd/tls/server.key
        debug_mode: false
      etcd_client:
        endpoints:
%{ for endpoint in etcd.endpoints ~}
          - "${endpoint}"
%{ endfor ~}
        connection_timeout: "300s"
        request_timeout: "300s"
        retry_interval: "10s"
        retries: 30
        auth:
          ca_cert: "/etc/terraform-backend-etcd/etcd/ca.crt"
%{ if etcd.client.certificate != "" ~}
          client_cert: "/etc/terraform-backend-etcd/etcd/client.crt"
          client_key: "/etc/terraform-backend-etcd/etcd/client.key"
%{ else ~}
          password_auth: /etc/terraform-backend-etcd/etcd/password.yml
%{ endif ~}
      remote_termination: false
  - path: /etc/systemd/system/terraform-backend-etcd.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Terraform Backend Service"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      Environment=ETCD_BACKEND_CONFIG_FILE=/etc/terraform-backend-etcd/config.yml
      User=root
      Group=root
      Type=simple
      Restart=always
      RestartSec=1
      ExecStart=/usr/local/bin/terraform-backend-etcd

      [Install]
      WantedBy=multi-user.target

%{ if install_dependencies ~}
packages:
  - curl
  - unzip
%{ endif ~}

runcmd:
%{ if install_dependencies ~}
  #Install etcd terraform backend service
  - curl -L https://github.com/Ferlab-Ste-Justine/terraform-backend-etcd/releases/download/v0.4.0/terraform-backend-etcd_0.4.0_linux_amd64.tar.gz -o /tmp/terraform-backend-etcd.tar.gz
  - mkdir -p /tmp/terraform-backend-etcd
  - tar zxvf /tmp/terraform-backend-etcd.tar.gz -C /tmp/terraform-backend-etcd
  - cp /tmp/terraform-backend-etcd/terraform-backend-etcd /usr/local/bin/terraform-backend-etcd
  - rm /tmp/terraform-backend-etcd.tar.gz
  - rm -r /tmp/terraform-backend-etcd
%{ endif ~}
  - cp /etc/terraform-backend-etcd/tls/ca.crt /usr/local/share/ca-certificates
  - update-ca-certificates
  - systemctl enable terraform-backend-etcd
  - systemctl start terraform-backend-etcd