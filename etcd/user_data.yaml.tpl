#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies ~}
users:   
  - name: etcd
    system: True
    lock_passwd: True
%{ endif ~}

write_files:
  #Etcd tls Certificates
  - path: /etc/etcd/tls/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, tls.ca_cert)}
  - path: /etc/etcd/tls/etcd.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, tls.server_cert)}
  - path: /etc/etcd/tls/etcd.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, tls.server_key)}
  #Etcd bootstrap authentication if node is responsible for it
%{ if etcd_host.bootstrap_authentication ~}
  - path: /opt/bootstrap_auth.sh
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/bash
      ROOT_USER=""
      while [ "$ROOT_USER" != "root" ]; do
          sleep 1
%{ if etcd_cluster.client_cert_auth ~}
          etcdctl user add --no-password --cacert=/etc/etcd/tls/ca.crt --cert=/etc/etcd/tls/etcd.crt --key=/etc/etcd/tls/etcd.key --endpoints=https://127.0.0.1:2379 --insecure-transport=false root
          ROOT_USER=$(etcdctl user list --cacert=/etc/etcd/tls/ca.crt --cert=/etc/etcd/tls/etcd.crt --key=/etc/etcd/tls/etcd.key --endpoints=https://127.0.0.1:2379 --insecure-transport=false | grep root)
%{ else ~}
          etcdctl user add --new-user-password="${etcd_cluster.root_password}" --cacert=/etc/etcd/tls/ca.crt --endpoints=https://127.0.0.1:2379 --insecure-transport=false root
          ROOT_USER=$(etcdctl user list --cacert=/etc/etcd/tls/ca.crt --endpoints=https://127.0.0.1:2379 --insecure-transport=false | grep root)
%{ endif ~}
      done
      ROOT_ROLES=""
      while [ -z "$ROOT_ROLES" ]; do
          sleep 1
%{ if etcd_cluster.client_cert_auth ~}
          etcdctl user grant-role --cacert=/etc/etcd/tls/ca.crt --cert=/etc/etcd/tls/etcd.crt --key=/etc/etcd/tls/etcd.key --endpoints=https://127.0.0.1:2379 --insecure-transport=false root root
          ROOT_ROLES=$(etcdctl user get --cacert=/etc/etcd/tls/ca.crt --cert=/etc/etcd/tls/etcd.crt --key=/etc/etcd/tls/etcd.key --endpoints=https://127.0.0.1:2379 --insecure-transport=false root | grep "Roles: root")
%{ else ~}
          etcdctl user grant-role --cacert=/etc/etcd/tls/ca.crt --endpoints=https://127.0.0.1:2379 --insecure-transport=false root root
          ROOT_ROLES=$(etcdctl user get --cacert=/etc/etcd/tls/ca.crt --endpoints=https://127.0.0.1:2379 --insecure-transport=false root | grep "Roles: root")
%{ endif ~}
      done
%{ if etcd_cluster.client_cert_auth ~}
      etcdctl auth enable --cacert=/etc/etcd/tls/ca.crt --cert=/etc/etcd/tls/etcd.crt --key=/etc/etcd/tls/etcd.key --endpoints=https://127.0.0.1:2379 --insecure-transport=false
%{ else ~}
      etcdctl auth enable --cacert=/etc/etcd/tls/ca.crt --endpoints=https://127.0.0.1:2379 --insecure-transport=false
%{ endif ~}
      while [ $? -ne 0 ]; do
          sleep 1
%{ if etcd_cluster.client_cert_auth ~}
          etcdctl auth enable --cacert=/etc/etcd/tls/ca.crt --cert=/etc/etcd/tls/etcd.crt --key=/etc/etcd/tls/etcd.key --endpoints=https://127.0.0.1:2379 --insecure-transport=false
%{ else ~}
          etcdctl auth enable --cacert=/etc/etcd/tls/ca.crt --endpoints=https://127.0.0.1:2379 --insecure-transport=false
%{ endif ~}
      done
%{ endif ~}
  #Etcd configuration file
  - path: /etc/etcd/conf.yml
    owner: root:root
    permissions: "0400"
    content: |
      data-dir: /var/lib/etcd
      quota-backend-bytes: ${etcd_cluster.space_quota}
      auto-compaction-mode: ${etcd_cluster.auto_compaction_mode}
      auto-compaction-retention: "${etcd_cluster.auto_compaction_retention}"
      name: ${etcd_host.name}
      initial-advertise-peer-urls: https://${etcd_host.ip}:2380
      listen-peer-urls: https://${etcd_host.ip}:2380
      listen-client-urls: https://${etcd_host.ip}:2379,https://127.0.0.1:2379
      advertise-client-urls: https://${etcd_host.ip}:2379
      initial-cluster-token: ${etcd_initial_cluster.token}
      initial-cluster-state: ${etcd_initial_cluster.state}
      initial-cluster: ${etcd_initial_cluster.members}
      peer-transport-security:
        trusted-ca-file: /etc/etcd/tls/ca.crt
        cert-file: /etc/etcd/tls/etcd.crt
        key-file: /etc/etcd/tls/etcd.key
        client-cert-auth: true
      client-transport-security:
%{ if etcd_cluster.client_cert_auth ~}
        trusted-ca-file: /etc/etcd/tls/ca.crt
%{ endif ~}
        cert-file: /etc/etcd/tls/etcd.crt
        key-file: /etc/etcd/tls/etcd.key
        client-cert-auth: ${etcd_cluster.client_cert_auth}
%{ if etcd_cluster.grpc_gateway_enabled ~}
      enable-grpc-gateway: true
%{ else ~}
      enable-grpc-gateway: false
%{ endif ~}
  #Etcd systemd configuration
  - path: /etc/systemd/system/etcd.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Etcd Service"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      Environment="ETCD_CONFIG_FILE=/etc/etcd/conf.yml"
      User=etcd
      Group=etcd
      Type=simple
      Restart=always
      RestartSec=1
      ExecStart=/usr/local/bin/etcd

      [Install]
      WantedBy=multi-user.target

runcmd:
  #Set etcd configs as owned by etcd
  - chown etcd:etcd -R /etc/etcd
%{ if install_dependencies ~}
  #Install etcd service binaries
  - wget -O /opt/etcd-v3.5.17-linux-amd64.tar.gz https://storage.googleapis.com/etcd/v3.5.17/etcd-v3.5.17-linux-amd64.tar.gz
  - mkdir -p /opt/etcd
  - tar xzvf /opt/etcd-v3.5.17-linux-amd64.tar.gz -C /opt/etcd
  - cp /opt/etcd/etcd-v3.5.17-linux-amd64/etcd /usr/local/bin/etcd
  - cp /opt/etcd/etcd-v3.5.17-linux-amd64/etcdctl /usr/local/bin/etcdctl
  - cp /opt/etcd/etcd-v3.5.17-linux-amd64/etcdutl /usr/local/bin/etcdutl
  - rm -f /opt/etcd-v3.5.17-linux-amd64.tar.gz
  - rm -rf /opt/etcd
%{ endif ~}
  #Create etcd service data directory
  - mkdir -p /var/lib/etcd
  - chown etcd:etcd -R /var/lib/etcd
  - chmod 0700 /var/lib/etcd
  #State etcd service
  - systemctl enable etcd
  - systemctl start etcd
  #Setup etcd authentication if node selected for that role 
%{ if etcd_host.bootstrap_authentication ~}
  - /opt/bootstrap_auth.sh
%{ endif ~}