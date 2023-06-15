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

%{ if install_dependencies ~}
packages:
  - curl
  - unzip
%{ endif ~}

runcmd:
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