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
%{ endif ~}

write_files:
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
%{ if is_fe_leader ~}
      ExecStart=/opt/starrocks/fe/bin/start_fe.sh --host_type FQDN --daemon
%{ else ~}
      ExecStart=/opt/starrocks/fe/bin/start_fe.sh --helper ${fe_leader_fqdn}:9010 --host_type FQDN --daemon
%{ endif ~}
%{ endif ~}
%{ if node_type == "be" ~}
      ExecStart=/opt/starrocks/be/bin/start_be.sh --daemon
%{ endif ~}
      ExecStop=/opt/starrocks/${node_type}/bin/stop_${node_type}.sh --daemon
      #ExecReload=/bin/kill --signal HUP $MAINPID
      KillMode=process
      KillSignal=SIGINT
      Restart=on-failure
      RestartSec=5
      TimeoutStopSec=30
      StartLimitInterval=60
      StartLimitBurst=3
      LimitNOFILE=65536
      LimitMEMLOCK=infinity

      [Install]
      WantedBy=multi-user.target

%{ if install_dependencies ~}
packages:
  - openjdk-11-jdk
%{ if node_type == "fe" && is_fe_leader ~}
  - mysql-client
%{ endif ~}
%{ endif ~}

runcmd:
  #Preparation: JDK configuration + LANG variable
  - echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> /etc/profile
  - echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/profile
  - echo 'export LANG=en_US.UTF8' >> /etc/profile
  - source /etc/profile

  #Preparation: Memory Overcommit + Swappiness + tcp_abort_on_overflow + somaxconn + max_map_count
  - echo 'vm.overcommit_memory=1' >> /etc/sysctl.conf
  - echo 'vm.swappiness=0' >> /etc/sysctl.conf
  - echo 'net.ipv4.tcp_abort_on_overflow=1' >> /etc/sysctl.conf
  - echo 'net.core.somaxconn=1024' >> /etc/sysctl.conf
  - echo 'vm.max_map_count=262144' >> /etc/sysctl.conf
  - sysctl -p

  #Preparation: Transparent Huge Pages
  - echo 'madvise' > /sys/kernel/mm/transparent_hugepage/enabled
  - echo 'madvise' > /sys/kernel/mm/transparent_hugepage/defrag

  #Preparation: Storage configurations
  - echo 'none' > /sys/block/vda/queue/scheduler

  #Preparation: Time zone
  - cp -f /usr/share/zoneinfo/America/Montreal /etc/localtime
  - hwclock

  #Preparation: ulimit configurations
  - echo '* soft nproc 65535' >> /etc/security/limits.conf
  - echo '* hard nproc 65535' >> /etc/security/limits.conf
  - echo '* soft nofile 655350' >> /etc/security/limits.conf
  - echo '* hard nofile 655350' >> /etc/security/limits.conf
  - echo '* soft stack unlimited' >> /etc/security/limits.conf
  - echo '* hard stack unlimited' >> /etc/security/limits.conf
  - echo '* hard memlock unlimited' >> /etc/security/limits.conf
  - echo '*          soft    nproc     65535' >> /etc/security/limits.d/20-nproc.conf
  - echo 'root       soft    nproc     65535' >> /etc/security/limits.d/20-nproc.conf

  #Preparation: Other
  - echo '120000' > /proc/sys/kernel/threads-max
  - echo '200000' > /proc/sys/kernel/pid_max

  #Preparation: Deployment files
  - cd /opt
  - for i in {1..10}; do wget -T 30 -c https://releases.starrocks.io/starrocks/StarRocks-${release_version}-ubuntu-amd64.tar.gz && break; done
  - tar xzf StarRocks-${release_version}-ubuntu-amd64.tar.gz StarRocks-${release_version}-ubuntu-amd64/${node_type} StarRocks-${release_version}-ubuntu-amd64/LICENSE.txt StarRocks-${release_version}-ubuntu-amd64/NOTICE.txt
  - mv StarRocks-${release_version}-ubuntu-amd64 starrocks
  - rm StarRocks-${release_version}-ubuntu-amd64.tar.gz

  #Configuration
%{ if node_type == "fe" ~}
  - mkdir starrocks/meta
  - echo 'meta_dir = /opt/starrocks/meta' >> starrocks/fe/conf/fe.conf
%{ endif ~}
%{ if node_type == "be" ~}
  - mkdir starrocks/storage
  - echo 'storage_root_path = /opt/starrocks/storage' >> starrocks/be/conf/be.conf
%{ endif ~}

  #Service
  - chown -R starrocks:starrocks starrocks
  - systemctl enable starrocks
  - systemctl start starrocks

  #Setup
%{ if node_type == "fe" && is_fe_leader ~}
  - mysql -h 127.0.0.1 -P 9030 -u root -e "SET PASSWORD = PASSWORD('${root_password}');"
%{ for fe_follower_fqdn in fe_follower_fqdns ~}
  - mysql -h 127.0.0.1 -P 9030 -u root -e "ALTER SYSTEM ADD FOLLOWER '${fe_follower_fqdn}:9010';"
%{ endfor ~}
%{ for be_fqdn in be_fqdns ~}
  - mysql -h 127.0.0.1 -P 9030 -u root -e "ALTER SYSTEM ADD BACKEND '${be_fqdn}:9050';"
%{ endfor ~}
%{ endif ~}
