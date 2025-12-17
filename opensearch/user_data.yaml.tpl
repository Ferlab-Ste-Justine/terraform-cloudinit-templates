#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies ~}
users:
  - name: opensearch
    system: true
    lock_passwd: true
%{ endif ~}

write_files:
  #Opensearch certs
  - path: /etc/opensearch/server-certs/server.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, tls.server_cert)}
  - path: /etc/opensearch/server-certs/server.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, tls.server_key)}
  - path: /etc/opensearch/ca-certs/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, tls.ca_cert)}
  - path: /etc/opensearch/client-certs/admin.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, tls.admin_cert)}
  - path: /etc/opensearch/client-certs/admin.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, tls.admin_key)}
%{ if try(snapshot_repository.ca_cert, "") != "" ~}
  - path: /etc/opensearch/snapshot-repository/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, snapshot_repository.ca_cert)}
  - path: /usr/local/bin/import_snapshot_repository_ca
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/bash
      set -euo pipefail

      CA_FILE=/etc/opensearch/snapshot-repository/ca.crt
      CACERTS="/opt/opensearch/jdk/lib/security/cacerts"
      OS_KEYSTORE="/etc/opensearch/configuration/opensearch.keystore"

      if [ ! -s "$CA_FILE" ]; then
        exit 0
      fi

      TMP_PREFIX="/tmp/snapshot-repo-ca"
      rm -f $${TMP_PREFIX}-*.pem || true
      awk -v prefix="$TMP_PREFIX" '/BEGIN CERTIFICATE/{i++} {print > (prefix "-" i ".pem")}' "$CA_FILE"

      shopt -s nullglob
      imported=0
      for cert in $${TMP_PREFIX}-*.pem; do
        if openssl x509 -in "$cert" -noout -text | grep -q "CA:TRUE"; then
          alias="snapshot-repository-$(basename "$cert" .pem)"
          if ! /opt/opensearch/jdk/bin/keytool -list -alias "$alias" -keystore "$CACERTS" -storepass changeit >/dev/null 2>&1; then
            /opt/opensearch/jdk/bin/keytool -importcert -noprompt \
              -alias "$alias" \
              -file "$cert" \
              -keystore "$CACERTS" \
              -storepass changeit
            imported=1
          fi
        fi
      done
      shopt -u nullglob
      rm -f $${TMP_PREFIX}-*.pem || true

      chown opensearch:opensearch "$OS_KEYSTORE"
      chmod 600 "$OS_KEYSTORE"

      if [ "$imported" -eq 1 ]; then
        systemctl restart opensearch
      fi
%{ endif ~}
%{ if length(try(opensearch_cluster.audit.external.http_endpoints, [])) > 0 ~}
%{ if try(opensearch_cluster.audit.external.auth.ca_cert, "") != "" ~}
  - path: /etc/opensearch/audit-external/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, opensearch_cluster.audit.external.auth.ca_cert)}
%{ endif ~}
%{ if try(opensearch_cluster.audit.external.auth.client_cert, "") != "" ~}
  - path: /etc/opensearch/audit-external/client.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, opensearch_cluster.audit.external.auth.client_cert)}
%{ endif ~}
%{ if try(opensearch_cluster.audit.external.auth.client_key, "") != "" ~}
  - path: /etc/opensearch/audit-external/client.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, opensearch_cluster.audit.external.auth.client_key)}
%{ endif ~}
%{ endif ~}
%{ if length(try(opensearch_cluster.index_lifecycle_policies, [])) > 0 ~}
  - path: /usr/local/bin/configure_opensearch_ilm
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/bash
      set -euo pipefail

      ENDPOINT="https://${opensearch_host.bind_ip}:9200"
      CURL_BASE=(
        curl --silent --show-error --fail
        --cacert /etc/opensearch/ca-certs/ca.crt
        --cert /etc/opensearch/client-certs/admin.crt
        --key /etc/opensearch/client-certs/admin.key
        -H 'Content-Type: application/json'
      )

%{ for policy in opensearch_cluster.index_lifecycle_policies ~}
      echo "Ensuring ILM policy ${policy.name}"
      "$${CURL_BASE[@]}" \
        -XPUT "$${ENDPOINT}/_ilm/policy/${policy.name}" \
        -d "{\"policy\":{\"phases\":{\"hot\":{\"actions\":{}},\"delete\":{\"min_age\":\"${policy.delete_min_age}\",\"actions\":{\"delete\":{}}}}}}"

      echo "Ensuring index template ${policy.template_name}"
      "$${CURL_BASE[@]}" \
        -XPUT "$${ENDPOINT}/_index_template/${policy.template_name}" \
        -d "{\"index_patterns\": ${jsonencode(policy.index_patterns)}, \"priority\": ${policy.template_priority}, \"template\": { \"settings\": { \"index.lifecycle.name\": \"${policy.name}\" } } }"

%{ endfor ~}
      echo "Configured ${length(opensearch_cluster.index_lifecycle_policies)} ILM policies"
%{ endif ~}
  - path: /usr/local/bin/bootstrap_opensearch
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/bash

      echo "Waiting for server to join cluster with green status"
      STATUS=$(curl --silent --cert /etc/opensearch/client-certs/admin.crt --key /etc/opensearch/client-certs/admin.key --cacert /etc/opensearch/ca-certs/ca.crt https://${opensearch_host.bind_ip}:9200/_cluster/health | jq ".status")
      while [ "$STATUS" != "\"green\"" ]; do
          sleep 1
          STATUS=$(curl --silent --cert /etc/opensearch/client-certs/admin.crt --key /etc/opensearch/client-certs/admin.key --cacert /etc/opensearch/ca-certs/ca.crt https://${opensearch_host.bind_ip}:9200/_cluster/health | jq ".status")
      done

%{ if opensearch_host.bootstrap_security ~}
      echo "Bootstraping opensearch security"
      export JAVA_HOME=/opt/opensearch/jdk
      chmod +x /opt/opensearch/plugins/opensearch-security/tools/securityadmin.sh
      /opt/opensearch/plugins/opensearch-security/tools/securityadmin.sh \
        -cd /etc/opensearch/configuration/opensearch-security \
        -icl -nhnv -cert /etc/opensearch/client-certs/admin.crt \
        -key /etc/opensearch/client-certs/admin-key-pk8.pem \
        -cacert /etc/opensearch/ca-certs/ca.crt \
        -t config

%{ endif ~}
      echo "Swaping bootstrap configuration for runtime configuration"
      cp /etc/opensearch/runtime-configuration/opensearch.yml /etc/opensearch/configuration/opensearch.yml
      chown opensearch:opensearch /etc/opensearch/configuration/opensearch.yml
  #opensearch configuration
  - path: /etc/opensearch/configuration/log4j2.properties
    owner: root:root
    permissions: "0644"
    content: |
      log4j.rootLogger = INFO, CONSOLE
      log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
      log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
      log4j.appender.CONSOLE.layout.pattern = [%d{ISO8601}][%-5p][%-25c{1.}] [%node_name]%marker %m%n
  - path: /etc/opensearch/configuration/jvm.options
    owner: root:root
    permissions: "0644"
    content: |
      #Heap
      -Xms__HEAP_SIZE__m
      -Xmx__HEAP_SIZE__m

      #G1GC Configuration
      -XX:+UseG1GC
      -XX:G1ReservePercent=25
      -XX:InitiatingHeapOccupancyPercent=30

      #performance analyzer
      -Djdk.attach.allowAttachSelf=true
      -Djava.security.policy=/opt/opensearch/plugins/opensearch-performance-analyzer/plugin-security.policy
      --add-opens=jdk.attach/sun.tools.attach=ALL-UNNAMED

      # JVM temporary directory
      -Djava.io.tmpdir=/opt/opensearch-jvm-temp

      #Might not be needed
      -Djava.security.manager=allow
  - path: /usr/local/bin/set_dynamic_opensearch_java_options
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/bash
      #Heap size
%{ if opensearch_host.cluster_manager ~}
      HEAP_SIZE=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') * 3 / 4 / 1024 ))
%{ else ~}
      HEAP_SIZE=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 2 / 1024 ))
%{ endif ~}
      sed "s/__HEAP_SIZE__/$HEAP_SIZE/g" -i /etc/opensearch/configuration/jvm.options
      #performance analyzer
      CLK_TCK=$(/usr/bin/getconf CLK_TCK)
      echo "-Dclk.tck=$CLK_TCK" >> /etc/opensearch/configuration/jvm.options
  - path: /usr/local/bin/adjust_tls_key_format
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/bash
      openssl pkcs8 -in /etc/opensearch/server-certs/server.key -topk8 -nocrypt -out /etc/opensearch/server-certs/server-key-pk8.pem
%{ if opensearch_host.bootstrap_security ~}
      openssl pkcs8 -in /etc/opensearch/client-certs/admin.key -topk8 -nocrypt -out /etc/opensearch/client-certs/admin-key-pk8.pem
%{ endif ~}
%{ if length(try(opensearch_cluster.audit.external.http_endpoints, [])) > 0 && try(opensearch_cluster.audit.external.auth.client_key, "") != "" ~}
      openssl pkcs8 -in /etc/opensearch/audit-external/client.key -topk8 -nocrypt -out /etc/opensearch/audit-external/client-key-pk8.pem
%{ endif ~}
  - path: /etc/opensearch/configuration/opensearch.yml
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, opensearch_bootstrap_conf)}
  - path: /etc/opensearch/runtime-configuration/opensearch.yml
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, opensearch_runtime_conf)}
  - path: /etc/opensearch/configuration/opensearch-security/config.yml
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, opensearch_security_conf.config)}
%{ if try(opensearch_cluster.audit.enabled, false) ~}
  - path: /etc/opensearch/configuration/opensearch-security/audit.yml
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, opensearch_security_conf.audit)}
%{ endif ~}
  - path: /etc/opensearch/configuration/opensearch-security/internal_users.yml
    owner: root:root
    permissions: "0444"
    content: |
      _meta:
        type: "internalusers"
        config_version: 2
  - path: /etc/opensearch/configuration/opensearch-security/roles.yml
    owner: root:root
    permissions: "0444"
    content: |
      _meta:
        type: "roles"
        config_version: 2
  - path: /etc/opensearch/configuration/opensearch-security/roles_mapping.yml
    owner: root:root
    permissions: "0444"
    content: |
      _meta:
        type: "rolesmapping"
        config_version: 2
  - path: /etc/opensearch/configuration/opensearch-security/action_groups.yml
    owner: root:root
    permissions: "0444"
    content: |
      _meta:
        type: "actiongroups"
        config_version: 2
  - path: /etc/opensearch/configuration/opensearch-security/allowlist.yml
    owner: root:root
    permissions: "0444"
    content: |
      _meta:
        type: "allowlist"
        config_version: 2

      config:
        enabled: false
  - path: /etc/opensearch/configuration/opensearch-security/tenants.yml
    owner: root:root
    permissions: "0444"
    content: |
      _meta:
        type: "tenants"
        config_version: 2
  - path: /etc/opensearch/configuration/opensearch-security/nodes_dn.yml
    owner: root:root
    permissions: "0444"
    content: |
      _meta:
        type: "nodesdn"
        config_version: 2
  - path: /etc/opensearch/configuration/opensearch-security/whitelist.yml
    owner: root:root
    permissions: "0444"
    content: |
      _meta:
        type: "whitelist"
        config_version: 2

      config:
        enabled: false
  #Performance analyser configuration
  - path: /etc/opensearch/configuration/opensearch-performance-analyzer/performance-analyzer.properties
    owner: root:root
    permissions: "0444"
    content: |
      metrics-location = /dev/shm/performanceanalyzer/
      metrics-deletion-interval = 1
      cleanup-metrics-db-files = true
      webservice-listener-port = 9600
      rpc-port = 9650
      metrics-db-file-prefix-path = /tmp/metricsdb_
      https-enabled = false
      plugin-stats-metadata = plugin-stats-metadata
      agent-stats-metadata = agent-stats-metadata
  - path: /etc/opensearch/configuration/opensearch-performance-analyzer/plugin-stats-metadata
    owner: root:root
    permissions: "0600"
    content: |
      Program=PerformanceAnalyzerPlugin
  - path: /etc/opensearch/configuration/opensearch-performance-analyzer/agent-stats-metadata
    owner: root:root
    permissions: "0600"
    content: |
      Program=PerformanceAnalyzerAgent
  #opensearch systemd configuration
  - path: /etc/systemd/system/opensearch.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Opensearch"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      Environment=OPENSEARCH_PATH_CONF=/etc/opensearch/configuration
      Environment=JAVA_HOME=/opt/opensearch/jdk
      Environment=OPENSEARCH_TMPDIR=
      Environment=LD_LIBRARY_PATH=/opt/opensearch/plugins/opensearch-knn/lib
      LimitNOFILE=65535
      LimitNPROC=4096
      LimitAS=infinity
      LimitFSIZE=infinity
      User=opensearch
      Group=opensearch
      Type=simple
      Restart=always
      RestartSec=1
      WorkingDirectory=/opt/opensearch
      ExecStart=/opt/opensearch/bin/opensearch

      [Install]
      WantedBy=multi-user.target

%{ if install_dependencies ~}
packages:
  - curl
  - jq
%{ endif ~}

runcmd:
  #Install Opensearch
%{ if install_dependencies ~}
  - wget -O /opt/opensearch.tar.gz https://artifacts.opensearch.org/releases/bundle/opensearch/2.2.1/opensearch-2.2.1-linux-x64.tar.gz
  - tar zxvf /opt/opensearch.tar.gz -C /opt
  - mv /opt/opensearch-2.2.1 /opt/opensearch
  - /opt/opensearch/bin/opensearch-plugin install -b https://github.com/aiven/prometheus-exporter-plugin-for-opensearch/releases/download/2.2.1.0/prometheus-exporter-2.2.1.0.zip
  - /opt/opensearch/bin/opensearch-plugin install -b repository-s3
  - chown -R opensearch:opensearch /opt/opensearch
  - rm /opt/opensearch.tar.gz
%{ endif ~}
  - mkdir -p /opt/opensearch-jvm-temp
  - chown -R opensearch:opensearch /opt/opensearch-jvm-temp
  - /usr/local/bin/set_dynamic_opensearch_java_options
  - /usr/local/bin/adjust_tls_key_format
  - echo 'vm.max_map_count=262144' >> /etc/sysctl.conf
  - echo 'vm.swappiness = 1' >> /etc/sysctl.conf
  - sysctl -p
  - chown -R opensearch:opensearch /etc/opensearch
  - systemctl enable opensearch.service
  - systemctl start opensearch.service
  - /usr/local/bin/bootstrap_opensearch
%{ if length(try(opensearch_cluster.index_lifecycle_policies, [])) > 0 ~}
  - /usr/local/bin/configure_opensearch_ilm
%{ endif ~}
%{ if try(snapshot_repository.access_key, "") != "" ~}
  - "printf '%s' '${base64encode(snapshot_repository.access_key)}' | base64 -d | OPENSEARCH_PATH_CONF=/etc/opensearch/configuration /opt/opensearch/bin/opensearch-keystore add --stdin --force s3.client.default.access_key"
%{ endif ~}
%{ if try(snapshot_repository.secret_key, "") != "" ~}
  - "printf '%s' '${base64encode(snapshot_repository.secret_key)}' | base64 -d | OPENSEARCH_PATH_CONF=/etc/opensearch/configuration /opt/opensearch/bin/opensearch-keystore add --stdin --force s3.client.default.secret_key"
%{ endif ~}
%{ if try(snapshot_repository.ca_cert, "") != "" ~}
  - /usr/local/bin/import_snapshot_repository_ca
%{ endif ~}
