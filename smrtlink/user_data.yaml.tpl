#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
  - path: /opt/smrtlink.env
    owner: root:root
    permissions: "0555"
    content: |
      SMRT_USER=${user}
      SMRT_ROOT=/opt/pacbio/smrtlink
%{ if tls_custom.cert != "" && tls_custom.key != "" ~}
  - path: /opt/tls_custom/smrtlink-site.crt
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, tls_custom.cert)}
  - path: /opt/tls_custom/smrtlink-site.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, tls_custom.key)}
%{ endif ~}
%{ if tls_custom.vault_agent_secret_path != "" ~}
  - path: /opt/tls_custom/vault-agent/smrtlink-site.crt.ctmpl
    owner: root:root
    permissions: "0440"
    content: |
      {{ with secret "${tls_custom.vault_agent_secret_path}" }}
      {{ .Data.data.cert }}
      {{ end }}
  - path: /opt/tls_custom/vault-agent/smrtlink-site.key.ctmpl
    owner: root:root
    permissions: "0440"
    content: |
      {{ with secret "${tls_custom.vault_agent_secret_path}" }}
      {{ .Data.data.key }}
      {{ end }}
  - path: /etc/vault-agent.d/config/tls_custom.hcl
    owner: root:root
    permissions: "0440"
    content: |
      template {
        source      = "/opt/tls_custom/vault-agent/smrtlink-site.crt.ctmpl"
        destination = "/opt/tls_custom/smrtlink-site.crt"
        exec {
          command = ["sudo", "-u", "${user}", "/opt/pacbio/smrtlink/admin/bin/restart-gui"]
        }
        perms       = "0444"
      }
      template {
        source      = "/opt/tls_custom/vault-agent/smrtlink-site.key.ctmpl"
        destination = "/opt/tls_custom/smrtlink-site.key"
        exec {
          command = ["sudo", "-u", "${user}", "/opt/pacbio/smrtlink/admin/bin/restart-gui"]
        }
        perms       = "0400"
      }
%{ endif ~}
%{ if db_backups.enabled ~}
  - path: /opt/smrtlink_cron.sh
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/bash
      DEFAULT_BCK_DIR="/var/lib/smrtlink/userdata/db_datadir/backups/manual"
      # Run backup
      /opt/pacbio/smrtlink/install/smrtlink-release_${release_version}/admin/bin/dbhelper --backup
      # Remove old backup symlinks + files without symlinks attached
      echo "  Cleaning backups older than ${db_backups.retention_days} day(s)..."
      find $DEFAULT_BCK_DIR -type l -mtime +${db_backups.retention_days} -exec rm {} \;
      files="$(find $DEFAULT_BCK_DIR -type f -mtime +${db_backups.retention_days})"
      for file in $files; do
        symlinks_attached="$(find -L $DEFAULT_BCK_DIR -xtype l -samefile "$file")"
        if [[ "$symlinks_attached" == "" ]]; then
          rm "$file"
        fi
      done
      echo "  Cleanup complete."
%{ endif ~}
  - path: /etc/systemd/system/smrtlink.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description=SMRT Link services
      After=nfs-client.target network.target autofs.service remote-fs.target multi-user.target

      [Service]
      User=${user}
      Type=forking
      TimeoutSec=600
      LimitNOFILE=8192
      ExecStart=/opt/pacbio/smrtlink/admin/bin/services-start
      ExecStop=/opt/pacbio/smrtlink/admin/bin/services-stop

      [Install]
      WantedBy=multi-user.target

%{ if install_dependencies ~}
packages:
  - unzip
  - python3-boto3
%{ endif ~}

runcmd:
  #Preparation: Environment variables
  - echo '. /opt/smrtlink.env' >> /etc/profile

  #Preparation: ulimit configurations
  - echo '${user} soft nofile 8192' >> /etc/security/limits.conf

  #Preparation: Deployment files
  - cd /opt
  - wget https://downloads.pacbcloud.com/public/software/installers/smrtlink-release_${release_version}.zip
  - unzip -j smrtlink-release_${release_version}.zip -d smrtlink-release
  - rm smrtlink-release_${release_version}.zip
  - mkdir pacbio
  - chown ${user}:${user} pacbio
%{ if domain_name != "" ~}
  - DOMAIN_ARG="--dnsname ${domain_name}"
%{ endif ~}
%{ if smtp.host != "" ~}
  - SMTP_ARGS="--mail-host ${smtp.host} --mail-port ${smtp.port}"
%{ if smtp.user != "" ~}
  - SMTP_ARGS="$SMTP_ARGS --mail-user ${smtp.user} --mail-password ${smtp.password}"
%{ endif ~}
%{ endif ~}
  - sudo -u ${user} ./$(ls smrtlink-release/*.run) --batch --lite ${install_lite} --jmstype NONE --rootdir /opt/pacbio/smrtlink --dbdatadir /var/lib/smrtlink/userdata/db_datadir --jobsroot /var/lib/smrtlink/userdata/jobs_root --nworkers ${workers_count} --enable-update false $DOMAIN_ARG $SMTP_ARGS
  - rm -r smrtlink-release

  #Preparation: Uploads folder symlink
  - mkdir -p /var/lib/smrtlink/userdata/uploads
  - chown ${user}:${user} /var/lib/smrtlink/userdata/uploads
  - rmdir pacbio/smrtlink/userdata/uploads
  - ln -s /var/lib/smrtlink/userdata/uploads pacbio/smrtlink/userdata/uploads
  - chown -h ${user}:${user} pacbio/smrtlink/userdata/uploads

  #Preparation: TLS custom configuration
%{ if (tls_custom.cert != "" && tls_custom.key != "") || tls_custom.vault_agent_secret_path != "" ~}
  - chown -R ${user}:${user} tls_custom
  - ln -s /opt/tls_custom pacbio/smrtlink/userdata/config/security
%{ endif ~}

  #Preparation: Database restore
%{ if restore_db ~}
  - LATEST_BCK_FILE=/var/lib/smrtlink/userdata/db_datadir/backups/manual/latest_smrtlinkdb.sql
  - while [ ! -f $LATEST_BCK_FILE ]; do echo "Backup file for restore is missing, retrying in 5 seconds..."; sleep 5; done;
  - sudo -u ${user} /opt/pacbio/smrtlink/install/smrtlink-release_${release_version}/admin/bin/dbhelper --restore smrtlinkdb --restore-file $LATEST_BCK_FILE
%{ endif ~}

  #Service
  - systemctl enable smrtlink
  - systemctl start smrtlink

  #Setup
%{ if keycloak_user_passwords.admin != "" ~}
  - ADMIN_PASS_OUTPUT=$(./pacbio/smrtlink/admin/bin/set-keycloak-creds --user admin --password '${keycloak_user_passwords.admin}' --admin-password 'admin' 2>&1)
  - if echo "$ADMIN_PASS_OUTPUT" | grep -q "^401 Client Error"; then echo "Password for user 'admin' has already been changed."; fi
%{ endif ~}
%{ if keycloak_user_passwords.pbicsuser != "" ~}
  - ./pacbio/smrtlink/admin/bin/set-keycloak-creds --user pbicsuser --password '${keycloak_user_passwords.pbicsuser}' --admin-password '${keycloak_user_passwords.admin}'
%{ endif ~}
%{ for user in keycloak_users ~}
  - USER_CREATE_OUTPUT=$(./pacbio/smrtlink/smrtcmds/bin/python3 pacbio/smrtlink/current/bundles/smrtlink-analysisservices-gui/current/private/pacbio/smrtlink-analysisservices-gui/bin/create-local-user '${user.id}' --password '${user.password}' --role '${user.role}' --firstname '${user.first_name}' --lastname '${user.last_name}' --email '${user.email}' --keycloak-password '${keycloak_user_passwords.admin}' 2>&1)
  - if echo "$USER_CREATE_OUTPUT" | grep -q "^409 Client Error"; then echo "User '${user.id}' has already been created."; else echo "$USER_CREATE_OUTPUT"; fi
%{ endfor ~}
  - ./pacbio/smrtlink/admin/bin/accept-user-agreement --install-metrics false --job-metrics false
%{ if revio.srs_transfer.name != "" ~}
  - ./pacbio/smrtlink/smrtcmds/developer/bin/pbservice-instrument create-transfer-location 'srs' --user 'admin' --password '${keycloak_user_passwords.admin}' --port '8243' '${revio.srs_transfer.name}' --description '${revio.srs_transfer.description}' --transfer-host '${revio.srs_transfer.host}' --dest-path '${revio.srs_transfer.dest_path}' --relative-path '${revio.srs_transfer.relative_path}' --transfer-user '${revio.srs_transfer.username}' --ssh-key '${revio.srs_transfer.ssh_key}'
%{ endif ~}
%{ if revio.s3compatible_transfer.name != "" ~}
  - ./pacbio/smrtlink/smrtcmds/developer/bin/pbservice-instrument create-transfer-location 's5cmd' --user 'admin' --password '${keycloak_user_passwords.admin}' --port '8243' '${revio.s3compatible_transfer.name}' --description '${revio.s3compatible_transfer.description}' --transfer-host '${revio.s3compatible_transfer.endpoint}' --dest-path '${revio.s3compatible_transfer.bucket}' --aws-region '${revio.s3compatible_transfer.region}' --relative-path '${revio.s3compatible_transfer.path}' --access-key '${revio.s3compatible_transfer.access_key}' --secret-key '${revio.s3compatible_transfer.secret_key}'
%{ endif ~}
%{ if revio.instrument.name != "" ~}
  - ./pacbio/smrtlink/smrtcmds/developer/bin/pbservice-instrument register --user 'admin' --password '${keycloak_user_passwords.admin}' --port '8243' --transfer-location '${revio.instrument.transfer_name}' --instrument-name '${revio.instrument.name}' '${revio.instrument.ip_address}' '${revio.instrument.secret_key}'
%{ endif ~}

  #Finalization: Database backups cron job
%{ if db_backups.enabled ~}
  - echo "${db_backups.cron_expression} ${user} /opt/smrtlink_cron.sh" >> /etc/crontab
%{ endif ~}

  #Finalization: Docker installation
%{ if install_dependencies ~}
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  - add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io
  - usermod -aG docker ${user}
%{ endif ~}
