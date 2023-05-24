#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies ~}
users:
  - name: coredns
    system: true
    lock_passwd: true
%{ endif ~}

write_files:
  #coredns
  - path: /etc/coredns/Corefile
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, corefile)}
  - path: /etc/systemd/system/coredns.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="DNS Service"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      User=coredns
      Group=coredns
      Type=simple
      Restart=always
      RestartSec=1
      ExecStart=/usr/local/bin/coredns -conf /etc/coredns/Corefile

      [Install]
      WantedBy=multi-user.target
  #Coredns zonefiles updater
  - path: /etc/coredns-zonefiles-updater/ca.crt
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, etcd.ca_certificate)}
%{ if etcd.client.certificate != "" ~}
  - path: /etc/coredns-zonefiles-updater/client.crt
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, etcd.client.certificate)}
  - path: /etc/coredns-zonefiles-updater/client.key
    owner: root:root
    permissions: "0440"
    content: |
      ${indent(6, etcd.client.key)}
%{ else ~}
  - path: /etc/coredns-zonefiles-updater/password.yml
    owner: root:root
    permissions: "0400"
    content: |
      username: ${etcd.client.username}
      password: ${etcd.client.password}
%{ endif ~}
  - path: /etc/coredns-zonefiles-updater/config.yml
    owner: root:root
    permissions: "0440"
    content: |
      filesystem:
        path: /opt/coredns/zonefiles
        files_permission: "700"
        directories_permission: "700"
      etcd_client:
        prefix: "${etcd.key_prefix}"
        endpoints:
%{ for endpoint in etcd.endpoints ~}
          - "${endpoint}"
%{ endfor ~}
        connection_timeout: "10s"
        request_timeout: "10s"
        retry_interval: "500ms"
        retries: 10
        auth:
          ca_cert: "/etc/coredns-zonefiles-updater/ca.crt"
%{ if etcd.client.certificate != "" ~}
          client_cert: "/etc/coredns-zonefiles-updater/client.crt"
          client_key: "/etc/coredns-zonefiles-updater/client.key"
%{ else ~}
          password_auth: /etc/coredns-zonefiles-updater/password.yml
%{ endif ~}
  - path: /etc/systemd/system/coredns-zonefiles-updater.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Coredns Zonefiles Updating Service"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      Environment=CONFS_AUTO_UPDATER_CONFIG_FILE=/etc/coredns-zonefiles-updater/config.yml
      User=coredns
      Group=coredns
      Type=simple
      Restart=always
      RestartSec=1
      WorkingDirectory=/opt/coredns/zonefiles
      ExecStart=/usr/local/bin/coredns-zonefiles-updater

      [Install]
      WantedBy=multi-user.target

%{ if install_dependencies ~}
packages:
  - curl
  - unzip
%{ endif ~}

runcmd:
  #Setup coredns auto updater service
%{ if install_dependencies ~}
  - curl -L https://github.com/Ferlab-Ste-Justine/configurations-auto-updater/releases/download/v0.4.0/configurations-auto-updater_0.4.0_linux_amd64.tar.gz -o /tmp/configurations-auto-updater_0.4.0_linux_amd64.tar.gz
  - mkdir -p /tmp/configurations-auto-updater
  - tar zxvf /tmp/configurations-auto-updater_0.4.0_linux_amd64.tar.gz -C /tmp/configurations-auto-updater
  - cp /tmp/configurations-auto-updater/configurations-auto-updater /usr/local/bin/coredns-zonefiles-updater
  - rm -rf /tmp/configurations-auto-updater
  - rm -f /tmp/configurations-auto-updater_0.4.0_linux_amd64.tar.gz
%{ endif ~}
  - mkdir -p /opt/coredns/zonefiles
  - chown -R coredns:coredns /opt/coredns/zonefiles
  - chown -R coredns:coredns /etc/coredns-zonefiles-updater
  - systemctl enable coredns-zonefiles-updater
  - systemctl start coredns-zonefiles-updater
  #Setup coredns service
%{ if install_dependencies ~}
  - curl -L https://github.com/Ferlab-Ste-Justine/ferlab-coredns/releases/download/v1.2.0/linux-amd64.zip --output linux-amd64.zip
  - unzip linux-amd64.zip
  - cp linux-amd64/coredns /usr/local/bin/
  - rm linux-amd64.zip
  - rm -r linux-amd64
%{ endif ~}
  - setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/coredns
  - systemctl enable coredns
  - systemctl start coredns