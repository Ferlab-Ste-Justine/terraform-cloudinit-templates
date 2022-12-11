#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
  #Fluentd config
  - path: /opt/fluentd.conf
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, fluentd_conf)}
  - path: /etc/systemd/system/fluentd.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Fluentd"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      User=root
      Group=root
      Type=simple
      Restart=always
      RestartSec=1
      ExecStart=fluentd -c /opt/fluentd.conf

      [Install]
      WantedBy=multi-user.target
  - path: /opt/fluentd_ca.crt
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, fluentd.forward.ca_cert)}

%{ if install_dependencies ~}
packages:
  - ruby-full
  - build-essential
%{ endif ~}

runcmd:
  #Fluentd setup
  - mkdir -p /opt/fluentd-state
  - chown root:root /opt/fluentd-state
  - chmod 0700 /opt/fluentd-state
%{ if install_dependencies ~}
  - gem install fluentd
  - gem install fluent-plugin-systemd -v 1.0.5
%{ endif ~}
  - systemctl enable fluentd.service
  - systemctl start fluentd.service