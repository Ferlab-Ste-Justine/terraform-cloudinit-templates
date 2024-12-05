#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies ~}
users:
  - name: ${user}
    system: true
    lock_passwd: true
    shell: /bin/bash
%{ endif ~}

write_files:
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
      LimitNPROC=8192
      ExecStart=/opt/pacbio/smrtlink/admin/bin/services-start --enable-keycloak-console
      ExecStop=/opt/pacbio/smrtlink/admin/bin/services-stop

      [Install]
      WantedBy=multi-user.target

%{ if install_dependencies ~}
packages:
  #- libglib2.0-dev
  #- libfuse3-dev
  #- autoconf
  #- automake
  #- libtool
  - unzip
%{ endif ~}

runcmd:
  #Preparation: ulimit configurations
  - echo '${user} soft nofile 8192' >> /etc/security/limits.conf
  - echo '${user} soft nproc 8192' >> /etc/security/limits.conf

  #Preparation: Deployment files
  - cd /opt
  - wget https://downloads.pacbcloud.com/public/software/installers/smrtlink-${sequencing_system}_${release_version}.zip
  - unzip smrtlink-${sequencing_system}_${release_version}.zip
  - rm smrtlink-${sequencing_system}_${release_version}.zip
  - mkdir pacbio
  - chown ${user}:${user} pacbio
%{ if smtp.host == "" ~}
  - sudo -u ${user} ./$(ls *.run) --lite ${install_lite} --dnsname ${domain_name} --jmstype NONE --rootdir /opt/pacbio/smrtlink --nworkers ${workers_count} --enable-update false --batch
%{ else ~}
%{ if smtp.user == "" ~}
  - sudo -u ${user} ./$(ls *.run) --lite ${install_lite} --dnsname ${domain_name} --jmstype NONE --rootdir /opt/pacbio/smrtlink --nworkers ${workers_count} --enable-update false --mail-host ${smtp.host} --mail-port ${smtp.port} --batch
%{ else ~}
  - sudo -u ${user} ./$(ls *.run) --lite ${install_lite} --dnsname ${domain_name} --jmstype NONE --rootdir /opt/pacbio/smrtlink --nworkers ${workers_count} --enable-update false --mail-host ${smtp.host} --mail-port ${smtp.port} --mail-user ${smtp.user} --mail-password ${smtp.password} --batch
%{ endif ~}
%{ endif ~}

  #Service
  - systemctl enable smrtlink
  - systemctl start smrtlink

  #Setup
  - /opt/pacbio/smrtlink/admin/bin/set-keycloak-creds --user admin --password 'mouse' --admin-password 'admin'
  - /opt/pacbio/smrtlink/admin/bin/set-keycloak-creds --user pbicsuser --password 'potato' --admin-password 'mouse'
  #- /opt/pacbio/smrtlink/admin/accept-user-agreement --install-metrics true --job-metrics true
