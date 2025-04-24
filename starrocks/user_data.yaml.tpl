#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies ~}
users:
  - name: starrocks
    system: true
    lock_passwd: true
    shell: /bin/bash
%{ endif ~}

write_files:
  - path: /opt/starrocks.env
    owner: root:root
    permissions: "0555"
    content: |
      JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
      PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/usr/lib/jvm/java-11-openjdk-amd64/bin
      LANG=en_US.UTF8
%{ if fe_config.ssl.enabled ~}
  - path: /opt/ssl/starrocks.crt
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, fe_config.ssl.cert)}
  - path: /opt/ssl/starrocks.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, fe_config.ssl.key)}
%{ endif ~}
%{ if fe_config.iceberg_rest.ca_cert != "" ~}
  - path: /etc/ca-certificates/iceberg_catalog/${fe_config.iceberg_rest.env_name}-iceberg-rest-ca.crt
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, fe_config.iceberg_rest.ca_cert)}
%{ endif ~}
  - path: /etc/systemd/system/starrocks.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="StarRocks - A high-performance analytical database"
      Documentation=https://docs.starrocks.io/
      Requires=network-online.target
      After=network-online.target
      ConditionFileNotEmpty=/opt/starrocks/${node_type}/conf/${node_type}.conf
      StartLimitIntervalSec=60
      StartLimitBurst=3

      [Service]
      User=starrocks
      Group=starrocks
      ProtectSystem=full
      ProtectHome=read-only
      PrivateTmp=yes
      PrivateDevices=yes
      SecureBits=keep-caps
      AmbientCapabilities=CAP_IPC_LOCK
      CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
      NoNewPrivileges=yes
%{ if node_type == "fe" ~}
%{ if fe_config.initial_leader.enabled ~}
      ExecStart=/opt/starrocks/fe/bin/start_fe.sh --host_type FQDN
%{ else ~}
      ExecStart=/opt/starrocks/fe/bin/start_fe.sh --helper ${fe_config.initial_follower.fe_leader_fqdn}:9010 --host_type FQDN
%{ endif ~}
%{ endif ~}
%{ if node_type == "be" ~}
      ExecStart=/opt/starrocks/be/bin/start_be.sh
%{ endif ~}
      ExecStop=/opt/starrocks/${node_type}/bin/stop_${node_type}.sh --graceful
      SuccessExitStatus=143
      Restart=on-failure
      RestartSec=5
      TimeoutStopSec=30
      StartLimitInterval=60
      StartLimitBurst=3
      LimitNPROC=65535
      LimitNOFILE=655350
      LimitSTACK=infinity
      LimitMEMLOCK=infinity

      EnvironmentFile=/opt/starrocks.env

      [Install]
      WantedBy=multi-user.target

%{ if install_dependencies ~}
packages:
  - openjdk-11-jdk
  - sysfsutils
%{ if node_type == "fe" ~}
  - mysql-client
%{ endif ~}
%{ endif ~}

runcmd:
  #Preparation: JDK configuration + LANG variable
  - echo '. /opt/starrocks.env' >> /etc/profile

  #Preparation: Memory Overcommit + Swappiness + tcp_abort_on_overflow + somaxconn + max_map_count + Other
  - echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf
  - echo 'vm.swappiness = 0' >> /etc/sysctl.conf
  - echo 'net.ipv4.tcp_abort_on_overflow = 1' >> /etc/sysctl.conf
  - echo 'net.core.somaxconn = 1024' >> /etc/sysctl.conf
  - echo 'vm.max_map_count = 262144' >> /etc/sysctl.conf
  - echo 'kernel.threads-max = 120000' >> /etc/sysctl.conf
  - echo 'kernel.pid_max = 200000' >> /etc/sysctl.conf
  - sysctl -p

  #Preparation: Transparent Huge Pages + Storage configurations
  ##Temporarily
  - echo 'madvise' > /sys/kernel/mm/transparent_hugepage/enabled
  - echo 'madvise' > /sys/kernel/mm/transparent_hugepage/defrag
  - echo 'none' > /sys/block/vda/queue/scheduler
  #Permanently
  - echo 'kernel/mm/transparent_hugepage/enabled = madvise' >> /etc/sysfs.conf
  - echo 'kernel/mm/transparent_hugepage/defrag = madvise' >> /etc/sysfs.conf
  - echo 'block/vda/queue/scheduler = none' >> /etc/sysfs.conf

  #Preparation: Time zone
  - cp -f /usr/share/zoneinfo/${timezone} /etc/localtime

  #Preparation: ulimit configurations
  - echo '* soft nproc 65535' >> /etc/security/limits.conf
  - echo '* hard nproc 65535' >> /etc/security/limits.conf
  - echo '* soft nofile 655350' >> /etc/security/limits.conf
  - echo '* hard nofile 655350' >> /etc/security/limits.conf
  - echo '* soft stack unlimited' >> /etc/security/limits.conf
  - echo '* hard stack unlimited' >> /etc/security/limits.conf
  - echo '* soft memlock unlimited' >> /etc/security/limits.conf
  - echo '* hard memlock unlimited' >> /etc/security/limits.conf
  - echo '*          soft    nproc     65535' >> /etc/security/limits.d/20-nproc.conf
  - echo 'root       soft    nproc     65535' >> /etc/security/limits.d/20-nproc.conf

  #Preparation: Deployment files
  - cd /opt
  - wget -T 30 -t 10 -c https://releases.starrocks.io/starrocks/StarRocks-${release_version}-ubuntu-amd64.tar.gz
  - tar xzf StarRocks-${release_version}-ubuntu-amd64.tar.gz StarRocks-${release_version}-ubuntu-amd64/${node_type} StarRocks-${release_version}-ubuntu-amd64/LICENSE.txt StarRocks-${release_version}-ubuntu-amd64/NOTICE.txt
  - mv StarRocks-${release_version}-ubuntu-amd64 starrocks
  - rm StarRocks-${release_version}-ubuntu-amd64.tar.gz

  #Configuration
%{ if node_type == "fe" ~}
  - mkdir starrocks/meta
  - echo 'meta_dir = /opt/starrocks/meta' >> starrocks/fe/conf/fe.conf
%{ if fe_config.ssl.enabled ~}
  - openssl pkcs12 -export -in ssl/starrocks.crt -inkey ssl/starrocks.key -out ssl/starrocks.p12 -passout pass:${fe_config.ssl.keystore_password}
  - chown -R starrocks:starrocks ssl
  - echo 'ssl_keystore_location = /opt/ssl/starrocks.p12' >> starrocks/fe/conf/fe.conf
  - echo 'ssl_keystore_password = ${fe_config.ssl.keystore_password}' >> starrocks/fe/conf/fe.conf
  - echo 'ssl_key_password = ${fe_config.ssl.keystore_password}' >> starrocks/fe/conf/fe.conf
%{ endif ~}
%{ if fe_config.iceberg_rest.ca_cert != "" ~}
  - keytool -import -noprompt -keystore /usr/lib/jvm/java-1.11.0-openjdk-amd64/lib/security/cacerts -file /etc/ca-certificates/iceberg_catalog/${fe_config.iceberg_rest.env_name}-iceberg-rest-ca.crt -storepass changeit -alias ic-${fe_config.iceberg_rest.env_name}
%{ endif ~}
%{ endif ~}
%{ if node_type == "be" ~}
  - mkdir starrocks/storage
  - echo 'storage_root_path = /opt/starrocks/storage' >> starrocks/be/conf/be.conf
%{ endif ~}
  - chmod 0400 starrocks/${node_type}/conf/${node_type}.conf

  #Service
  - chown -R starrocks:starrocks starrocks
  - systemctl enable starrocks
  - systemctl start starrocks

  #Setup
%{ if node_type == "fe" && fe_config.initial_leader.enabled ~}
  - while ! mysqladmin -s -h127.0.0.1 -P9030 -uroot ping; do echo "mysqld is not alive, retrying in 5 seconds..."; sleep 5; done;
  - mysql -h127.0.0.1 -P9030 -uroot -e "SET PASSWORD = PASSWORD('${fe_config.initial_leader.root_password}');"
%{ for fe_follower_fqdn in fe_config.initial_leader.fe_follower_fqdns ~}
  - mysql -h127.0.0.1 -P9030 -uroot -p${fe_config.initial_leader.root_password} -e"ALTER SYSTEM ADD FOLLOWER '${fe_follower_fqdn}:9010';"
%{ endfor ~}
%{ for be_fqdn in fe_config.initial_leader.be_fqdns ~}
  - mysql -h127.0.0.1 -P9030 -uroot -p${fe_config.initial_leader.root_password} -e"ALTER SYSTEM ADD BACKEND '${be_fqdn}:9050';"
%{ endfor ~}
%{ for user in fe_config.initial_leader.users ~}
  - mysql -h127.0.0.1 -P9030 -uroot -p${fe_config.initial_leader.root_password} -e"CREATE USER '${user.name}' IDENTIFIED BY '${user.password}' DEFAULT ROLE '${user.default_role}';"
%{ endfor ~}
%{ endif ~}
