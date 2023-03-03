#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
%{ if object_store.ca_cert != "" ~}
  - path: /etc/s3-outgoing-sync/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, object_store.ca_cert)}
%{ endif ~}
  #Rclone configs
  - path: /root/.config/rclone/rclone.conf
    owner: root:root
    permissions: "0400"
    content: |
      [minio]
      type = s3
      provider = Minio
      env_auth = true
      access_key_id = ${object_store.access_key}
      secret_access_key = ${object_store.secret_key}
      region = ${object_store.region}
      endpoint = ${object_store.url}
      location_constraint = 
%{ if object_store.server_side_encryption != "" ~}
      server_side_encryption = ${object_store.server_side_encryption}
%{ endif ~}
  #Rclone Sync Script
  - path: /opt/outgoing_sync.sh
    owner: root:root
    permissions: "0500"
    content: |
      #!/usr/bin/env sh

      set -xe

      %{ for path in backup.paths ~}
%{ if object_store.ca_cert != "" ~}
      rclone sync --ca-cert /etc/s3-outgoing-sync/ca.crt ${path} minio:${backup.bucket}${path}
%{ else ~}
      rclone sync ${path} minio:${backup.bucket}${path}
%{ endif ~}
      %{ endfor ~}
  #Rclone Sync Systemd Configuration
  - path: /etc/systemd/system/s3-outgoing-sync.timer
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Run S3 Outgoing Sync Recurrently"
      Requires=s3-outgoing-sync.service

      [Timer]
      Unit=s3-outgoing-sync.service
      OnCalendar=${backup.calendar}

      [Install]
      WantedBy=timers.target
  - path: /etc/systemd/system/s3-outgoing-sync.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="S3 Outgoing Sync"
      Wants=network-online.target
      After=network-online.target

      [Service]
      User=root
      Group=root
      Type=simple
      ExecStart=/opt/outgoing_sync.sh

      [Install]
      WantedBy=multi-user.target

%{ if install_dependencies ~}
packages:
  - curl
  - unzip
%{ endif ~}

runcmd:
%{ if install_dependencies ~}
  #Install rclone
  - curl -L https://github.com/rclone/rclone/releases/download/v1.61.1/rclone-v1.61.1-linux-amd64.zip -o /tmp/rclone-v1.61.1-linux-amd64.zip
  - mkdir -p /tmp/rclone
  - unzip /tmp/rclone-v1.61.1-linux-amd64.zip -d /tmp/rclone
  - cp /tmp/rclone/rclone-v1.61.1-linux-amd64/rclone /usr/local/bin/rclone
  - rm -rf /tmp/rclone
  - rm -f /tmp/rclone-v1.61.1-linux-amd64.zip
%{ endif ~}
  #Start rclone
  - systemctl enable s3-outgoing-sync.timer
  - systemctl start s3-outgoing-sync.timer