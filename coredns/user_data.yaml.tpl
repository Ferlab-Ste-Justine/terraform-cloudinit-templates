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
  #coredns corefile
  - path: /etc/coredns/Corefile
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, corefile)}
  #Coredns systemd configuration
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
  - path: /etc/coredns-zonefiles-updater/ca.crt
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, etcd.ca_certificate)}
%{ if etcd.client.username == "" ~}
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
%{ endif ~}
  #Coredns auto updater systemd configuration
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
      Environment=CONNECTION_TIMEOUT=10s
      Environment=REQUEST_TIMEOUT=10s
      Environment=REQUEST_RETRIES=0
      Environment=FILESYSTEM_PATH=/opt/coredns/zonefiles
      Environment=ETCD_ENDPOINTS=${join(",", etcd.endpoints)}
      Environment=CA_CERT_PATH=/etc/coredns-zonefiles-updater/ca.crt
%{ if etcd.client.username == "" ~}
      Environment=USER_CERT_PATH=/etc/coredns-zonefiles-updater/client.crt
      Environment=USER_KEY_PATH=/etc/coredns-zonefiles-updater/client.key
%{ else ~}
      Environment=USER_NAME=${etcd.client.username}
      Environment=USER_PASSWORD=${etcd.client.password}
%{ endif ~}
      Environment=ETCD_KEY_PREFIX=${etcd.key_prefix}
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
  - curl -L https://github.com/Ferlab-Ste-Justine/configurations-auto-updater/releases/download/v0.3.0/configurations-auto-updater_0.3.0_linux_amd64.tar.gz -o /tmp/configurations-auto-updater_0.3.0_linux_amd64.tar.gz
  - mkdir -p /tmp/configurations-auto-updater
  - tar zxvf /tmp/configurations-auto-updater_0.3.0_linux_amd64.tar.gz -C /tmp/configurations-auto-updater
  - cp /tmp/configurations-auto-updater/configurations-auto-updater /usr/local/bin/coredns-zonefiles-updater
  - rm -rf /tmp/configurations-auto-updater
  - rm -f /tmp/configurations-auto-updater_0.3.0_linux_amd64.tar.gz
%{ endif ~}
  - mkdir -p /opt/coredns/zonefiles
  - chown -R coredns:coredns /opt/coredns/zonefiles
  - chown -R coredns:coredns /etc/coredns-zonefiles-updater
  - systemctl enable coredns-zonefiles-updater
  - systemctl start coredns-zonefiles-updater
  #Setup coredns service
%{ if install_dependencies ~}
  - curl -L https://github.com/Ferlab-Ste-Justine/ferlab-coredns/releases/download/v1.0.0/linux-amd64.zip --output linux-amd64.zip
  - unzip linux-amd64.zip
  - cp linux-amd64/coredns /usr/local/bin/
  - rm linux-amd64.zip
  - rm -r linux-amd64
%{ endif ~}
  - setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/coredns
  - systemctl enable coredns
  - systemctl start coredns