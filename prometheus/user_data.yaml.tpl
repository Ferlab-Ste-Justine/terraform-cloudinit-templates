#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies ~}
users:
  - name: prometheus
    system: true
    lock_passwd: true
    sudo: "ALL= NOPASSWD: /bin/systemctl reload prometheus.service"
%{ endif ~}

write_files:
%{ if !install_dependencies ~}
  - path: /etc/sudoers.d/prometheus
    owner: root:root
    permissions: "0440"
    content: |
      prometheus ALL= NOPASSWD: /bin/systemctl reload prometheus.service
%{ endif ~}
  - path: /etc/systemd/system/prometheus.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Metrics Service"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      User=prometheus
      Group=prometheus
      Type=simple
      Restart=always
      RestartSec=1
      ExecStart=/usr/local/bin/prometheus \
          --config.file=/etc/prometheus/configs/prometheus.yml \
          --web.console.templates=/etc/prometheus/consoles \
          --web.console.libraries=/etc/prometheus/console_libraries \
          --web.external-url=${prometheus.web.external_url} \
          --web.max-connections=${prometheus.web.max_connections} \
          --web.read-timeout=${prometheus.web.read_timeout} \
          --storage.tsdb.path=/var/lib/prometheus/data \
          --storage.tsdb.retention.time=${prometheus.retention.time} \
          --storage.tsdb.retention.size=${prometheus.retention.size}
      ExecReload=/bin/kill -HUP $MAINPID

      [Install]
      WantedBy=multi-user.target
  - path: /usr/local/bin/reload-prometheus-configs
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/sh
      PROMETHEUS_STATUS=$(systemctl is-active prometheus.service)
      if [ $PROMETHEUS_STATUS = "active" ]; then
        sudo systemctl reload prometheus.service
      fi
  - path: /etc/prometheus-config-updater/etcd/ca.crt
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, etcd.ca_certificate)}
%{ if etcd.client.certificate != "" ~}
  - path: /etc/prometheus-config-updater/etcd/client.crt
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, etcd.client.certificate)}
  - path: /etc/prometheus-config-updater/etcd/client.key
    owner: root:root
    permissions: "0440"
    content: |
      ${indent(6, etcd.client.key)}
%{ else ~}
  - path: /etc/prometheus-config-updater/etcd/password.yml
    owner: root:root
    permissions: "0400"
    content: |
      username: ${etcd.client.username}
      password: ${etcd.client.password}
%{ endif ~}
  - path: /etc/prometheus-config-updater/configs.yml
    owner: root:root
    permissions: "0440"
    content: |
      notification_command: ["/usr/local/bin/reload-prometheus-configs"]
      filesystem:
        path: /etc/prometheus/configs/
        files_permission: "0770"
        directories_permission: "0770"
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
          ca_cert: "/etc/prometheus-config-updater/etcd/ca.crt"
%{ if etcd.client.certificate != "" ~}
          client_cert: "/etc/prometheus-config-updater/etcd/client.crt"
          client_key: "/etc/prometheus-config-updater/etcd/client.key"
%{ else ~}
          password_auth: /etc/prometheus-config-updater/etcd/password.yml
%{ endif ~}
  #Prometheus config updater systemd configuration
  - path: /etc/systemd/system/prometheus-config-updater.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Prometheus Configurations Updating Service"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      Environment=CONFS_AUTO_UPDATER_CONFIG_FILE=/etc/prometheus-config-updater/configs.yml
      User=prometheus
      Group=prometheus
      Type=simple
      Restart=always
      RestartSec=1
      WorkingDirectory=/opt
      ExecStart=/usr/local/bin/prometheus-config-updater

      [Install]
      WantedBy=multi-user.target

%{ if install_dependencies ~}
packages:
  - curl
%{ endif ~}

runcmd:
  #Setup prometheus auto updater service
%{ if install_dependencies ~}
  - curl -L https://github.com/Ferlab-Ste-Justine/configurations-auto-updater/releases/download/v0.4.0/configurations-auto-updater_0.4.0_linux_amd64.tar.gz -o /tmp/configurations-auto-updater_0.4.0_linux_amd64.tar.gz
  - mkdir -p /tmp/configurations-auto-updater
  - tar zxvf /tmp/configurations-auto-updater_0.4.0_linux_amd64.tar.gz -C /tmp/configurations-auto-updater
  - cp /tmp/configurations-auto-updater/configurations-auto-updater /usr/local/bin/prometheus-config-updater
  - rm -rf /tmp/configurations-auto-updater
  - rm -f /tmp/configurations-auto-updater_0.4.0_linux_amd64.tar.gz
  - mkdir /etc/prometheus
  - chown prometheus:prometheus /etc/prometheus
%{ endif ~}
  - chown -R prometheus:prometheus /etc/prometheus-config-updater
  - systemctl enable prometheus-config-updater
  - systemctl start prometheus-config-updater
  #Setup prometheus service
%{ if install_dependencies ~}
  - curl -L https://github.com/prometheus/prometheus/releases/download/v2.44.0/prometheus-2.44.0.linux-amd64.tar.gz --output prometheus.tar.gz
  - mkdir -p /tmp/prometheus
  - tar zxvf prometheus.tar.gz -C /tmp/prometheus
  - cp -r /tmp/prometheus/prometheus-2.44.0.linux-amd64/console_libraries /etc/prometheus/console_libraries
  - chown -R prometheus:prometheus /etc/prometheus/console_libraries
  - cp -r /tmp/prometheus/prometheus-2.44.0.linux-amd64/consoles /etc/prometheus/consoles
  - chown -R prometheus:prometheus /etc/prometheus/consoles
  - cp /tmp/prometheus/prometheus-2.44.0.linux-amd64/prometheus /usr/local/bin/prometheus
  - cp /tmp/prometheus/prometheus-2.44.0.linux-amd64/promtool /usr/local/bin/promtool
  - rm -r /tmp/prometheus
  - rm prometheus.tar.gz
%{ endif ~}
  - mkdir -p /var/lib/prometheus/data
  - chown -R prometheus:prometheus /var/lib/prometheus
  - systemctl enable prometheus
  - systemctl start prometheus