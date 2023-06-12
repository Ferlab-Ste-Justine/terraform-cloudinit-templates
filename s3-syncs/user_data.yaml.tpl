#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
%{ if object_store.ca_cert != "" ~}
  - path: /etc/s3-sync/ca.crt
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
      [s3]
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
  #Rclone Outgoing Sync Script
  - path: /opt/s3_outgoing_sync.sh
    owner: root:root
    permissions: "0500"
    content: |
      #!/usr/bin/env sh

      set -xe

%{ for path in outgoing_sync.paths ~}
      rclone ${outgoing_sync_rclone_args} sync ${outgoing_sync.fs_base_path}${path} s3:${outgoing_sync.bucket}${path}
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
      OnCalendar=${outgoing_sync.calendar}

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
      ExecStart=/opt/s3_outgoing_sync.sh

      [Install]
      WantedBy=multi-user.target
  #Rclone Incoming Sync Script
  - path: /opt/s3_incoming_sync.sh
    owner: root:root
    permissions: "0500"
    content: |
      #!/usr/bin/env sh

      set -xe

%{ for path in incoming_sync.paths ~}
      rclone sync ${incoming_sync_rclone_args} s3:${incoming_sync.bucket}${path} ${incoming_sync.fs_base_path}${path}
%{ endfor ~}
  #Rclone Sync Systemd Configuration
  - path: /etc/systemd/system/s3-incoming-sync.timer
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Run S3 Incoming Sync Recurrently"
      Requires=s3-incoming-sync.service

      [Timer]
      Unit=s3-incoming-sync.service
      OnCalendar=${incoming_sync.calendar}

      [Install]
      WantedBy=timers.target
  - path: /etc/systemd/system/s3-incoming-sync.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="S3 Incoming Sync"
      Wants=network-online.target
      After=network-online.target

      [Service]
      User=root
      Group=root
      Type=simple
      ExecStart=/opt/s3_incoming_sync.sh

      [Install]
      WantedBy=multi-user.target
  - path: /opt/s3_start_sync_services.sh
    owner: root:root
    permissions: "0500"
    content: |
      #!/usr/bin/env sh

      set -e

%{ if length(incoming_sync.paths) > 0 ~}
%{ if incoming_sync.sync_once ~}
      systemctl start --wait s3-incoming-sync.service
      SUCCESS=$(journalctl -u s3-incoming-sync.service | grep "s3-incoming-sync.service: Succeeded")
      if [ -z "$SUCCESS" ]
      then
        echo "Failed to synchronize from S3"
        exit 1
      fi
      echo "Synchronized from S3"
      systemctl disable s3-incoming-sync.service
%{ else ~}
      systemctl enable s3-incoming-sync.timer
      systemctl start s3-incoming-sync.timer
%{ endif ~}
%{ endif ~}

%{ if length(outgoing_sync.paths) > 0 ~}
      systemctl enable s3-outgoing-sync.timer
      systemctl start s3-outgoing-sync.timer
%{ endif ~}

%{ if install_dependencies ~}
packages:
  - curl
  - unzip
%{ endif ~}

runcmd:
%{ if install_dependencies ~}
  #Install rclone
  - curl -L https://github.com/rclone/rclone/releases/download/v1.62.2/rclone-v1.62.2-linux-amd64.zip -o /tmp/rclone-v1.62.2-linux-amd64.zip
  - mkdir -p /tmp/rclone
  - unzip /tmp/rclone-v1.62.2-linux-amd64.zip -d /tmp/rclone
  - cp /tmp/rclone/rclone-v1.62.2-linux-amd64/rclone /usr/local/bin/rclone
  - rm -rf /tmp/rclone
  - rm -f /tmp/rclone-v1.62.2-linux-amd64.zip
%{ endif ~}
  - /opt/s3_start_sync_services.sh