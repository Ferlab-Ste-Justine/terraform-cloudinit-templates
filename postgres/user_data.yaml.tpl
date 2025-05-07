#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
  #Postgres Certs
  - path: /etc/postgres/tls/server.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, postgres.server_key)}
  - path: /etc/postgres/tls/server.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, postgres.server_cert)}
  - path: /etc/postgres/tls/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, postgres.ca_cert)}
  #Patroni Certs
  - path: /etc/patroni/tls/api-server.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, patroni.api.server_key)}
  - path: /etc/patroni/tls/api-server.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, patroni.api.server_cert)}
  - path: /etc/patroni/tls/api-client.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, patroni.api.client_key)}
  - path: /etc/patroni/tls/api-client.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, patroni.api.client_cert)}
  - path: /etc/patroni/tls/api-ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, patroni.api.ca_cert)}
  - path: /etc/patroni/tls/etcd-ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, etcd.ca_cert)}
  #Patroni
  - path: /etc/patroni/conf.yml
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, patroni_conf)}
  - path: /etc/systemd/system/patroni.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Postgres Patroni"
      Wants=network-online.target ensure-softdog.service
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      User=postgres
      Group=postgres
      Type=simple
      Restart=always
      RestartSec=1
      ExecStart=patroni /etc/patroni/conf.yml

      [Install]
      WantedBy=multi-user.target
  - path: /usr/local/bin/ensure-softdog
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/sh

      SOFTDOG_LOADED=$(lsmod | grep softdog)
      if [ -z "$SOFTDOG_LOADED" ]; then
        modprobe softdog
      fi
  - path: /etc/systemd/system/ensure-softdog.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Ensure the softdog module is loaded"
      StartLimitIntervalSec=0

      [Service]
      User=root
      Group=root
      Type=simple
      ExecStart=/usr/local/bin/ensure-softdog

%{ if install_dependencies ~}
packages:
  - python3
  - python3-pip
  - lsb-release
  - wget
  - gnupg-agent
  - libpq-dev
%{ endif ~}
runcmd:
  #Install postgres
%{ if install_dependencies ~}
  - echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
  - wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
  - apt-get update
  - apt-get install -y postgresql-14 postgresql-contrib-14
  - systemctl stop postgresql
  - systemctl disable postgresql
  - rm /var/log/postgresql/*
  - rm -r /var/lib/postgresql/14/main
%{ endif ~}
  - mkdir -p /var/lib/postgresql/14/data
  - chmod 0700 /var/lib/postgresql/14/data
  - chown postgres:postgres /var/lib/postgresql/14/data
  #Install patroni
  - echo 'KERNEL=="watchdog", OWNER="postgres", GROUP="postgres"' > /etc/udev/rules.d/watchdog.rules
  - modprobe softdog
  - chown -R postgres:postgres /etc/patroni
  - chown -R postgres:postgres /etc/postgres
%{ if install_dependencies ~}
  - pip3 install --upgrade pip
  - pip3 install psycopg2>=2.5.4
%{ if patroni_version != "" ~}
  - pip3 install patroni[etcd3]==${patroni_version}
%{ else ~}
  - pip3 install patroni[etcd3]
%{ endif ~}
%{ endif ~}
  - systemctl enable patroni.service
  - systemctl start patroni.service