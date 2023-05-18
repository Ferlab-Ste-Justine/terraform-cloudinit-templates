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
  - path: /etc/fluent-bit-customization/default-config/fluent-bit-service.conf
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, fluentbit_service_conf)}
  - path: /etc/fluent-bit-customization/default-config/fluent-bit-inputs.conf
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, fluentbit_inputs_conf)}
  - path: /etc/fluent-bit-customization/default-config/fluent-bit-output.conf
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, fluentbit_output_conf)}
  - path: /etc/fluent-bit-customization/default-config/fluent-bit-static.conf
    owner: root:root
    permissions: "0444"
    content: |
      @INCLUDE /etc/fluent-bit-customization/default-config/fluent-bit-service.conf

      @INCLUDE /etc/fluent-bit-customization/default-config/fluent-bit-inputs.conf

      @INCLUDE /etc/fluent-bit-customization/default-config/fluent-bit-output.conf
  - path: /etc/fluent-bit-customization/default-config/fluent-bit-dynamic.conf
    owner: root:root
    permissions: "0444"
    content: |
      @INCLUDE /etc/fluent-bit-customization/dynamic-config/index.conf
  - path: /usr/local/bin/reload-fluent-bit-configs
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/sh
      FLUENTBIT_STATUS=$(systemctl fluent-bit.service)
      if [ $FLUENTBIT_STATUS = "active" ]; then
        systemctl reload fluent-bit.service
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
      ExecReload=/bin/kill -HUP $MAINPID
      Restart=always

      [Install]
      WantedBy=multi-user.target
%{ if etcd.enabled ~}
  - path: /etc/fluent-bit-config-updater/etcd/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, etcd.ca_certificate)}
%{ if etcd.client.certificate != "" ~}
  - path: /etc/fluent-bit-config-updater/etcd/client.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, etcd.client.certificate)}
  - path: /etc/fluent-bit-config-updater/etcd/client.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, etcd.client.key)}
%{ else ~}
  - path: /etc/fluent-bit-config-updater/etcd/password.yml
    owner: root:root
    permissions: "0400"
    content: |
      username: ${etcd.client.username}
      password: ${etcd.client.password}
%{ endif ~}
  - path: /etc/fluent-bit-config-updater/config.yml
    owner: root:root
    permissions: "0400"
    content: |
      NotificationCommand: ["/usr/local/bin/reload-fluent-bit-configs"]
      filesystem:
        path: "/etc/fluent-bit-customization/dynamic-config"
        files_permission: "700"
        directories_permission: "700"
      etcd_client:
        prefix: "${etcd.key_prefix}"
        endpoints:
%{ for endpoint in etcd.endpoints ~}
          - "${endpoint}"
%{ endfor ~}
        connection_timeout: "60s"
        request_timeout: "60s"
        retry_interval: "4s"
        retries: 15
        auth:
          ca_cert: "/etc/fluent-bit-config-updater/etcd/ca.crt"
%{ if etcd.client.certificate != "" ~}
          client_cert: "/etc/fluent-bit-config-updater/etcd/client.crt"
          client_key: "/etc/fluent-bit-config-updater/etcd/client.key"
%{ else ~}
          password_auth: /etc/fluent-bit-config-updater/etcd/password.yml
%{ endif ~}
  - path: /etc/systemd/system/fluent-bit-config-updater.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Fluent Bit Configurations Updating Service"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      Environment=CONFS_AUTO_UPDATER_CONFIG_FILE=/etc/fluent-bit-config-updater/config.yml
      User=root
      Group=root
      Type=simple
      Restart=always
      RestartSec=1
      WorkingDirectory=/etc/fluent-bit-customization/dynamic-config
      ExecStart=/usr/local/bin/fluent-bit-config-updater

      [Install]
      WantedBy=multi-user.target
%{ endif ~}

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
%{ if etcd.enabled ~}
#Install auto updater
  - curl -L https://github.com/Ferlab-Ste-Justine/configurations-auto-updater/releases/download/v0.4.0/configurations-auto-updater_0.4.0_linux_amd64.tar.gz -o /tmp/configurations-auto-updater_0.4.0_linux_amd64.tar.gz
  - mkdir -p /tmp/configurations-auto-updater
  - tar zxvf /tmp/configurations-auto-updater_0.4.0_linux_amd64.tar.gz -C /tmp/configurations-auto-updater
  - cp /tmp/configurations-auto-updater/configurations-auto-updater /usr/local/bin/fluent-bit-config-updater
  - rm -rf /tmp/configurations-auto-updater
  - rm -f /tmp/configurations-auto-updater_0.4.0_linux_amd64.tar.gz
%{ endif ~}
%{ endif ~}
  - mkdir -p /var/lib/fluent-bit/systemd-db
  - chmod 007 /var/lib/fluent-bit/systemd-db
%{ if etcd.enabled ~}
  - mkdir -p /etc/fluent-bit-customization/dynamic-config
  - chmod 007 /etc/fluent-bit-customization/dynamic-config
  - cp /etc/fluent-bit-customization/default-config/fluent-bit-dynamic.conf /etc/fluent-bit/fluent-bit.conf
  - systemctl enable fluent-bit-config-updater.service
  - systemctl start fluent-bit-config-updater.service
%{ else ~}
  - cp /etc/fluent-bit-customization/default-config/fluent-bit-static.conf /etc/fluent-bit/fluent-bit.conf
%{ endif ~}
  - systemctl enable fluent-bit.service
  - systemctl start fluent-bit.service