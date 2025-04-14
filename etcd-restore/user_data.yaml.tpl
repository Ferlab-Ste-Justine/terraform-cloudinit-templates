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
  - path: /etc/etcd/restore/config.yml
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, restore_conf)}
  - path: /etc/etcd/restore/s3_keys.yml
    owner: root:root
    permissions: "0400"
    content: |
      access_key: "${restore.s3.access_key}"
      secret_key: "${restore.s3.secret_key}"
%{ if restore.encryption_key != "" ~}
  - path: /etc/etcd/restore/master.key
    owner: root:root
    permissions: "0400"
    content: ${restore.encryption_key}
%{ endif ~}
%{ if restore.s3.ca_cert != "" ~}
  - path: /etc/etcd/restore/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, restore.s3.ca_cert)}
%{ endif ~}

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
  - wget -O /opt/etcd-backup.tar.gz https://github.com/Ferlab-Ste-Justine/etcd-backup/releases/download/v0.3.0/etcd-backup_0.3.0_linux_amd64.tar.gz
  - mkdir -p /opt/etcd-backup
  - tar xzvf /opt/etcd-backup.tar.gz -C /opt/etcd-backup
  - cp /opt/etcd-backup/etcd-backup /usr/local/bin/etcd-backup
  - rm /opt/etcd-backup.tar.gz
  - rm -rf /opt/etcd-backup
%{ endif ~}
  - mkdir -p /var/lib/etcd-restore/snapshots
  - etcd-backup restore ${etcd_backup_params}
  - chown etcd:etcd -R /var/lib/etcd
  - chmod 0700 /var/lib/etcd