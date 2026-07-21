#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if dependencies.install ~}
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
      JAVA_HOME=${dependencies.java_home}
      PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:${dependencies.java_home}/bin
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
%{ if fe_config.ranger != null ~}
  - path: /opt/ranger/ranger-starrocks-audit.xml
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, ranger_audit_conf)}
  - path: /opt/ranger/ranger-starrocks-security.xml
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, ranger_security_conf)}
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
      ConditionFileNotEmpty=/opt/starrocks/${install_dir}/conf/${node_type}.conf
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
%{ if node_type == "cn" ~}
      ExecStart=/opt/starrocks/${install_dir}/bin/start_cn.sh
%{ endif ~}
      ExecStop=/opt/starrocks/${install_dir}/bin/stop_${node_type}.sh --graceful
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

%{ if dependencies.install ~}
packages:
%{ for package in dependencies.packages.common ~}
  - ${package}
%{ endfor ~}
%{ if node_type == "fe" ~}
%{ for package in dependencies.packages.frontend ~}
  - ${package}
%{ endfor ~}
%{ endif ~}
%{ endif ~}

runcmd:
  #Preparation: Hostnames
%{ if hosts_file_patch.enabled ~}
  - sed -i "1i $(hostname -I | awk '{print $1}') ${hosts_file_patch.fqdn}" /etc/hosts
%{ endif ~}

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
  - mkdir -p starrocks
  - wget -T 30 -t 10 -c -O starrocks.tar.gz ${dependencies.starrocks_tar_url}
  - tar xzf starrocks.tar.gz -C starrocks --wildcards --strip-components=1 '*/${install_dir}' '*/LICENSE.txt' '*/NOTICE.txt'
  - rm starrocks.tar.gz

  #Configuration
%{ if node_type == "fe" ~}
  - if [ -e ${fe_config.meta_dir}/ROLE ] || [ -d ${fe_config.meta_dir}/bdb ]; then touch /tmp/fe-meta-preexisting; fi
  - mkdir -p ${fe_config.meta_dir}
  - chown starrocks:starrocks ${fe_config.meta_dir}
  - echo 'meta_dir = ${fe_config.meta_dir}' >> starrocks/fe/conf/fe.conf
%{ if fe_config.shared_data.enabled ~}
  - echo 'run_mode = shared_data' >> starrocks/fe/conf/fe.conf
  - echo 'enable_load_volume_from_conf = true' >> starrocks/fe/conf/fe.conf
  - echo 'cloud_native_storage_type = ${fe_config.shared_data.storage_type}' >> starrocks/fe/conf/fe.conf
  - echo 'aws_s3_endpoint = ${fe_config.shared_data.s3_endpoint}' >> starrocks/fe/conf/fe.conf
  - echo 'aws_s3_path = ${fe_config.shared_data.s3_path}' >> starrocks/fe/conf/fe.conf
%{ if fe_config.shared_data.s3_region != "" ~}
  - echo 'aws_s3_region = ${fe_config.shared_data.s3_region}' >> starrocks/fe/conf/fe.conf
%{ endif ~}
%{ if fe_config.shared_data.use_instance_profile ~}
  - echo 'aws_s3_use_instance_profile = true' >> starrocks/fe/conf/fe.conf
  - echo 'aws_s3_use_aws_sdk_default_behavior = true' >> starrocks/fe/conf/fe.conf
%{ else ~}
  - echo 'aws_s3_access_key = ${fe_config.shared_data.access_key}' >> starrocks/fe/conf/fe.conf
  - echo 'aws_s3_secret_key = ${fe_config.shared_data.secret_key}' >> starrocks/fe/conf/fe.conf
%{ endif ~}
%{ endif ~}
%{ if fe_config.ssl.enabled ~}
  - openssl pkcs12 -export -in ssl/starrocks.crt -inkey ssl/starrocks.key -out ssl/starrocks.p12 -passout pass:${fe_config.ssl.keystore_password}
  - chown -R starrocks:starrocks ssl
  - echo 'ssl_keystore_location = /opt/ssl/starrocks.p12' >> starrocks/fe/conf/fe.conf
  - echo 'ssl_keystore_password = ${fe_config.ssl.keystore_password}' >> starrocks/fe/conf/fe.conf
  - echo 'ssl_key_password = ${fe_config.ssl.keystore_password}' >> starrocks/fe/conf/fe.conf
  - echo 'ssl_force_secure_transport = ${fe_config.ssl.force_secure_transport}' >> starrocks/fe/conf/fe.conf
%{ endif ~}
%{ if fe_config.iceberg_rest.ca_cert != "" ~}
  - keytool -import -noprompt -keystore ${dependencies.java_home}/lib/security/cacerts -file /etc/ca-certificates/iceberg_catalog/${fe_config.iceberg_rest.env_name}-iceberg-rest-ca.crt -storepass changeit -alias ic-${fe_config.iceberg_rest.env_name}
%{ endif ~}
%{ for conf_line in fe_config.additional_conf ~}
  - echo '${conf_line}' >> starrocks/fe/conf/fe.conf
%{ endfor ~}
%{ if fe_config.ranger != null ~}
  - echo 'access_control = ranger' >> starrocks/fe/conf/fe.conf
  - cp /opt/ranger/ranger-starrocks-audit.xml /opt/ranger/ranger-starrocks-security.xml starrocks/fe/conf/
  - chmod 0400 starrocks/fe/conf/ranger-starrocks-security.xml
%{ endif ~}
%{ endif ~}
%{ if node_type == "be" ~}
  - mkdir -p ${be_storage_root_path}
  - chown starrocks:starrocks ${be_storage_root_path}
  - echo 'storage_root_path = ${be_storage_root_path}' >> starrocks/be/conf/be.conf
%{ endif ~}
%{ if node_type == "cn" ~}
  - mkdir -p ${cn_config.storage_root_path}
  - chown starrocks:starrocks ${cn_config.storage_root_path}
  - echo 'storage_root_path = ${cn_config.storage_root_path}' >> starrocks/${install_dir}/conf/cn.conf
%{ if cn_config.priority_networks != "" ~}
  - echo 'priority_networks = ${cn_config.priority_networks}' >> starrocks/${install_dir}/conf/cn.conf
%{ endif ~}
  - echo 'mem_limit = ${cn_config.mem_limit}' >> starrocks/${install_dir}/conf/cn.conf
  - echo 'datacache_mem_size = ${cn_config.datacache_mem_size}' >> starrocks/${install_dir}/conf/cn.conf
  - echo 'datacache_disk_size = ${cn_config.datacache_disk_size}' >> starrocks/${install_dir}/conf/cn.conf
%{ endif ~}
  - chmod 0400 starrocks/${install_dir}/conf/${node_type}.conf

  #Service
  - chown -R starrocks:starrocks starrocks
  - systemctl enable starrocks
  - systemctl start starrocks

  #Setup
%{ if node_type == "fe" && fe_config.initial_leader.enabled ~}
  - |
    if [ -f /tmp/fe-meta-preexisting ]; then
      echo "Existing FE metadata detected; skipping initial cluster bootstrap."
    else
%{ if fe_config.initial_leader.root_password.shell_source != null ~}
      . ${fe_config.initial_leader.root_password.shell_source}
%{ else ~}
      ROOT_PW='${fe_config.initial_leader.root_password.literal}'
%{ endif ~}
      while ! mysqladmin -s -h127.0.0.1 -P9030 -uroot ping; do echo "mysqld is not alive, retrying in 5 seconds..."; sleep 5; done
      echo "SET PASSWORD = PASSWORD('$ROOT_PW');" | mysql -h127.0.0.1 -P9030 -uroot
      export MYSQL_PWD="$ROOT_PW"
%{ for fe_follower_fqdn in fe_config.initial_leader.fe_follower_fqdns ~}
      mysql -h127.0.0.1 -P9030 -uroot -e "ALTER SYSTEM ADD FOLLOWER '${fe_follower_fqdn}:9010';"
%{ endfor ~}
%{ for be_fqdn in fe_config.initial_leader.be_fqdns ~}
      mysql -h127.0.0.1 -P9030 -uroot -e "ALTER SYSTEM ADD BACKEND '${be_fqdn}:9050';"
%{ endfor ~}
%{ for cn_fqdn in fe_config.initial_leader.cn_fqdns ~}
      mysql -h127.0.0.1 -P9030 -uroot -e "ALTER SYSTEM ADD COMPUTE NODE '${cn_fqdn}:9050';"
%{ endfor ~}
%{ for user in fe_config.initial_leader.users ~}
      echo "CREATE USER '${user.name}' IDENTIFIED BY '${user.password}' DEFAULT ROLE '${user.default_role}';" | mysql -h127.0.0.1 -P9030 -uroot
%{ endfor ~}
      unset MYSQL_PWD
    fi
%{ endif ~}
