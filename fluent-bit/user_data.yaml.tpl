#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
  - path: /etc/fluent-bit-customization/forward_ca.crt
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, fluentbit.forward.ca_cert)}
  - path: /etc/fluent-bit-customization/fluent-bit.conf
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, fluentbit_conf)}
  - path: /etc/fluent-bit-customization/fluent-bit.conf.template
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, fluentbit_conf_template)}
  - path: /usr/local/bin/reload-fluent-bit-configs
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/sh
      FLUENTBIT_STATUS=$(systemctl fluent-bit.service)
      if [ $FLUENTBIT_STATUS = "active" ]; then
        sudo systemctl reload fluent-bit.service
      fi
  - path: /etc/systemd/system/fluent-bit.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description=Fluent Bit
      Documentation=https://docs.fluentbit.io/manual/
      Requires=network.target
      After=network.target

      [Service]
      Type=simple
      EnvironmentFile=-/etc/sysconfig/fluent-bit
      EnvironmentFile=-/etc/default/fluent-bit
      ExecStart=/opt/fluent-bit/bin/fluent-bit --enable-hot-reload -c /etc/fluent-bit/fluent-bit.conf
      Restart=always

      [Install]
      WantedBy=multi-user.target

%{ if install_dependencies ~}
packages:
  - curl
%{ endif ~}

runcmd:
%{ if install_dependencies ~}
#Install fluentbit
  - curl https://packages.fluentbit.io/fluentbit.key | gpg --dearmor > /usr/share/keyrings/fluentbit-keyring.gpg
  - echo "deb [signed-by=/usr/share/keyrings/fluentbit-keyring.gpg] https://packages.fluentbit.io/$(lsb_release --id --short | tr '[:upper:]' '[:lower:]')/$(lsb_release --codename --short) $(lsb_release --codename --short) main" >> /etc/apt/sources.list 
  - apt-get update
  - apt-get install -y fluent-bit
%{ endif ~}
  - mkdir -p /var/lib/fluent-bit/systemd-db
  - cp /etc/fluent-bit-customization/fluent-bit.conf /etc/fluent-bit/fluent-bit.conf
  - systemctl enable fluent-bit.service
  - systemctl start fluent-bit.service