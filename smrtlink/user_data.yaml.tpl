#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies ~}
users:
  - name: ${user.name}
    lock_passwd: true
    shell: /bin/bash
%{ if length(user.ssh_authorized_keys) > 0 ~}
    ssh_authorized_keys:
%{ for key in user.ssh_authorized_keys ~}
      - "${key}"
%{ endfor ~}
%{ endif ~}
%{ endif ~}

write_files:
  - path: /opt/smrtlink.env
    owner: root:root
    permissions: "0555"
    content: |
      SMRT_USER=${user.name}
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
  - path: /etc/systemd/system/smrtlink.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description=SMRT Link services
      After=nfs-client.target network.target autofs.service remote-fs.target multi-user.target

      [Service]
      User=${user.name}
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
%{ endif ~}

runcmd:
  #Preparation: Environment variables
  - echo '. /opt/smrtlink.env' >> /etc/profile

  #Preparation: ulimit configurations
  - echo '${user.name} soft nofile 8192' >> /etc/security/limits.conf

  #Preparation: Deployment files
  - cd /opt
  - wget https://downloads.pacbcloud.com/public/software/installers/smrtlink-release_${release_version}.zip
  - unzip -j smrtlink-release_${release_version}.zip -d smrtlink-release
  - rm smrtlink-release_${release_version}.zip
  - mkdir pacbio
  - chown ${user.name}:${user.name} pacbio
  - mkdir -p /var/lib/smrtlink
  - chown ${user.name}:${user.name} /var/lib/smrtlink
%{ if domain_name != "" ~}
  - DOMAIN_ARG="--dnsname ${domain_name}"
%{ endif ~}
%{ if smtp.host != "" ~}
  - SMTP_ARGS="--mail-host ${smtp.host} --mail-port ${smtp.port}"
%{ if smtp.user != "" ~}
  - SMTP_ARGS="$SMTP_ARGS --mail-user ${smtp.user} --mail-password ${smtp.password}"
%{ endif ~}
%{ endif ~}
  - sudo -u ${user.name} ./$(ls smrtlink-release/*.run) --batch --lite ${install_lite} --jmstype NONE --rootdir /opt/pacbio/smrtlink --dbdatadir /var/lib/smrtlink/userdata/db_datadir --jobsroot /var/lib/smrtlink/userdata/jobs_root --nworkers ${workers_count} --enable-update false $DOMAIN_ARG $SMTP_ARGS
  - rm -r smrtlink-release

  #Preparation: TLS custom configuration
%{ if tls_custom.cert != "" && tls_custom.key != "" ~}
  - chown -R ${user.name}:${user.name} tls_custom
  - ln -s /opt/tls_custom pacbio/smrtlink/userdata/config/security
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
  - ./pacbio/smrtlink/smrtcmds/developer/bin/pbservice-instrument create-transfer-location 'srs' --user 'admin' --password '${keycloak_user_passwords.admin}' --port '8243' '${revio.srs_transfer.name}' --description '${revio.srs_transfer.description}' --transfer-host '${revio.srs_transfer.host}' --dest-path '${revio.srs_transfer.dest_path}' --transfer-user '${revio.srs_transfer.username}' --ssh-key '${revio.srs_transfer.ssh_key}'
  - ./pacbio/smrtlink/smrtcmds/developer/bin/pbservice-instrument register --user 'admin' --password '${keycloak_user_passwords.admin}' --port '8243' --transfer-location '${revio.srs_transfer.name}' --instrument-name '${revio.instrument.name}' '${revio.instrument.ip_address}' '${revio.instrument.secret_key}'
%{ endif ~}
