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
%{ if try(snapshot_repository.enabled, false) ~}
%{ if try(snapshot_repository.ca_cert, "") != "" ~}
  - path: /etc/opensearch/snapshot-repository/ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, snapshot_repository.ca_cert)}
  - path: /etc/opensearch/snapshot-repository/manifest-ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, snapshot_repository.ca_cert)}
%{ else ~}
  - path: /etc/opensearch/snapshot-repository/.keep
    owner: root:root
    permissions: "0400"
    content: |
      keep
%{ endif ~}
  - path: /var/log/opensearch-snapshots.log
    owner: root:root
    permissions: "0644"
    content: |
      Snapshot log initialized ${timestamp()}
  - path: /etc/opensearch/snapshot-repository/manifest.conf
    owner: root:root
    permissions: "0400"
    content: |
      bucket=${snapshot_repository.bucket}
      manifest_path=opensearch-snapshot-manifest.log
  - path: /usr/local/bin/import_snapshot_repository_ca
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/bash
      set -euo pipefail

      CA_FILE=/etc/opensearch/snapshot-repository/ca.crt
      if [ ! -f "$CA_FILE" ]; then
        exit 0
      fi

      STORE=/opt/opensearch/jdk/lib/security/cacerts
      ALIAS="snapshot-repository-ca"

      if /opt/opensearch/jdk/bin/keytool -list -alias "$ALIAS" -keystore "$STORE" -storepass changeit >/dev/null 2>&1; then
        exit 0
      fi

      /opt/opensearch/jdk/bin/keytool -importcert -noprompt -alias "$ALIAS" -file "$CA_FILE" -keystore "$STORE" -storepass changeit

  - path: /usr/local/bin/configure_opensearch_snapshot_repository
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/bash
      set -euo pipefail

      if [ "${tostring(opensearch_host.bootstrap_security)}" != "true" ]; then
        exit 0
      fi

      PAYLOAD_FILE=$(mktemp)
      cat <<'JSON' > "$PAYLOAD_FILE"
      {
        "type": "s3",
        "settings": {
          "bucket": "${snapshot_repository.bucket}",
          "endpoint": "${snapshot_repository.endpoint}",
          "region": "${snapshot_repository.region}",
          "protocol": "${snapshot_repository.protocol}",
          "path_style_access": ${snapshot_repository.path_style_access ? "true" : "false"},
          "client": "default"%{ if snapshot_repository.base_path != "" ~},
          "base_path": "${snapshot_repository.base_path}"%{ endif ~}
        }
      }
      JSON

      curl --silent --show-error --fail \
        --cert /etc/opensearch/client-certs/admin.crt \
        --key /etc/opensearch/client-certs/admin.key \
        --cacert /etc/opensearch/ca-certs/ca.crt \
        -H "Content-Type: application/json" \
        -XPUT https://${opensearch_host.bind_ip}:9200/_snapshot/${snapshot_repository.repository_name} \
        --data-binary @"$PAYLOAD_FILE"

      rm -f "$PAYLOAD_FILE"
  - path: /usr/local/bin/update_snapshot_manifest
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/bash
      set -euo pipefail

      if [ "${tostring(opensearch_host.bootstrap_security)}" != "true" ]; then
        exit 0
      fi

      LOG_FILE=/var/log/opensearch-snapshots.log
      CONF=/etc/opensearch/snapshot-repository/manifest.conf
      ENDPOINT="${snapshot_repository.endpoint}"
      ACCESS_KEY="${snapshot_repository.access_key}"
      SECRET_KEY="${snapshot_repository.secret_key}"
      CA_CERT_FILE=/etc/opensearch/snapshot-repository/manifest-ca.crt
      CONFIG_DIR=/root/.mc

      if [ ! -f "$LOG_FILE" ] || [ ! -f "$CONF" ]; then
        exit 0
      fi

      if [ ! -f "$CA_CERT_FILE" ]; then
        echo "Manifest upload aborted: CA certificate missing" >&2
        exit 1
      fi

      source "$CONF"

      if [ -z "$ENDPOINT" ] || [ -z "$ACCESS_KEY" ] || [ -z "$SECRET_KEY" ]; then
        exit 0
      fi

      TMP_MANIFEST=$(mktemp)
      cp "$LOG_FILE" "$TMP_MANIFEST"

      mkdir -p "$CONFIG_DIR/certs/CAs"
      cp "$CA_CERT_FILE" "$CONFIG_DIR/certs/CAs/minio-ca.crt"

      /usr/local/bin/mc --config-dir "$CONFIG_DIR" alias set manifest "$ENDPOINT" "$ACCESS_KEY" "$SECRET_KEY"
      /usr/local/bin/mc --config-dir "$CONFIG_DIR" cp "$TMP_MANIFEST" "manifest/$${bucket}/$${manifest_path}"
      /usr/local/bin/mc alias rm manifest >/dev/null 2>&1
      rm -f "$TMP_MANIFEST"

  - path: /usr/local/bin/run_periodic_opensearch_snapshot
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/bash
      set -euo pipefail

      TIMESTAMP=$(date --utc +%Y%m%d%H%M%S)
      UNIQUE=$(uuidgen | tr 'A-Z' 'a-z')
      SNAPSHOT_NAME="auto-$${TIMESTAMP}-$${UNIQUE}"

      RESPONSE=$(curl --silent --show-error \
        --cert /etc/opensearch/client-certs/admin.crt \
        --key /etc/opensearch/client-certs/admin.key \
        --cacert /etc/opensearch/ca-certs/ca.crt \
        -H "Content-Type: application/json" \
        -XPUT "https://${opensearch_host.bind_ip}:9200/_snapshot/${snapshot_repository.repository_name}/$${SNAPSHOT_NAME}?wait_for_completion=false")

      LOG_LINE="$(date --utc +%Y-%m-%dT%H:%M:%SZ) snapshot=$${SNAPSHOT_NAME}"
      STATUS="response=$${RESPONSE}"

      echo "$${LOG_LINE} $${STATUS}" >> /var/log/opensearch-snapshots.log

      if echo "$${RESPONSE}" | grep -q '"accepted":true'; then
        /usr/local/bin/update_snapshot_manifest || true
        echo "$${LOG_LINE} $${STATUS}"
      else
        echo "$${LOG_LINE} manifest_update=skipped" >> /var/log/opensearch-snapshots.log
      fi

  - path: /etc/systemd/system/opensearch-snapshot.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description=Create periodic OpenSearch snapshot
      Wants=update-opensearch-snapshot-manifest.service
      Wants=network-online.target
      After=network-online.target

      [Service]
      Type=oneshot
      ExecStart=/usr/local/bin/run_periodic_opensearch_snapshot

  - path: /etc/systemd/system/update-opensearch-snapshot-manifest.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description=Publish snapshot manifest to MinIO
      Requires=opensearch-snapshot.service
      After=opensearch-snapshot.service

      [Service]
      Type=oneshot
      ExecStart=/usr/local/bin/update_snapshot_manifest

  - path: /etc/systemd/system/opensearch-snapshot.timer
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description=Run OpenSearch snapshot periodically

      [Timer]
      OnBootSec=${snapshot_repository.timer_on_boot_sec}s
      OnUnitActiveSec=${snapshot_repository.timer_interval_sec}s
      Persistent=true

      [Install]
      WantedBy=timers.target
%{ endif ~}
%{ if try(snapshot_restore.enabled, false) ~}
  - path: /usr/local/bin/restore_opensearch_snapshot
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/bash
      set -euo pipefail

      if [ "${tostring(opensearch_host.bootstrap_security)}" != "true" ]; then
        exit 0
      fi

      if [ -z "${snapshot_restore.repository_name}" ] || [ -z "${snapshot_restore.snapshot_name}" ]; then
        echo "Snapshot restore parameters are incomplete" >&2
        exit 1
      fi

      echo "Waiting for OpenSearch cluster to become ready before restore"
      STATUS=$(curl --silent --cert /etc/opensearch/client-certs/admin.crt --key /etc/opensearch/client-certs/admin.key --cacert /etc/opensearch/ca-certs/ca.crt https://${opensearch_host.bind_ip}:9200/_cluster/health | jq -r ".status")
      until [ "$STATUS" = "green" ] || [ "$STATUS" = "yellow" ]; do
        sleep 5
        STATUS=$(curl --silent --cert /etc/opensearch/client-certs/admin.crt --key /etc/opensearch/client-certs/admin.key --cacert /etc/opensearch/ca-certs/ca.crt https://${opensearch_host.bind_ip}:9200/_cluster/health | jq -r ".status")
      done

      PAYLOAD_FILE=$(mktemp)
      cat <<'JSON' > "$PAYLOAD_FILE"
      {
        "include_global_state": ${snapshot_restore.include_global_state ? "true" : "false"}%{ if length(snapshot_restore.indices) > 0 ~},
        "indices": "${join(",", snapshot_restore.indices)}"%{ else ~},
        "indices": "*,-.opendistro_security"%{ endif ~}%{ if snapshot_restore.rename_pattern != "" ~},
        "rename_pattern": "${snapshot_restore.rename_pattern}"%{ endif ~}%{ if snapshot_restore.rename_replacement != "" ~},
        "rename_replacement": "${snapshot_restore.rename_replacement}"%{ endif ~}
      }
      JSON

      curl --silent --show-error \
        --cert /etc/opensearch/client-certs/admin.crt \
        --key /etc/opensearch/client-certs/admin.key \
        --cacert /etc/opensearch/ca-certs/ca.crt \
        -H "Content-Type: application/json" \
        -XPOST "https://${opensearch_host.bind_ip}:9200/_snapshot/${snapshot_restore.repository_name}/${snapshot_restore.snapshot_name}/_restore?wait_for_completion=${snapshot_restore.wait_for_completion ? "true" : "false"}" \
        --data-binary @"$PAYLOAD_FILE"

      rm -f "$PAYLOAD_FILE"
%{ endif ~}
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
%{ if try(snapshot_repository.enabled, false) ~}
  - /opt/opensearch/bin/opensearch-plugin install -b repository-s3
  - curl -sSL -o /usr/local/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc
  - chmod +x /usr/local/bin/mc
%{ endif ~}
  - chown -R opensearch:opensearch /opt/opensearch
  - rm /opt/opensearch.tar.gz
%{ endif ~}
%{ if try(snapshot_repository.enabled, false) ~}
  - "OPENSEARCH_PATH_CONF=/etc/opensearch/configuration /opt/opensearch/bin/opensearch-keystore list >/dev/null 2>&1 || OPENSEARCH_PATH_CONF=/etc/opensearch/configuration /opt/opensearch/bin/opensearch-keystore create"
  - "printf '%s' '${base64encode(snapshot_repository.access_key)}' | base64 -d | OPENSEARCH_PATH_CONF=/etc/opensearch/configuration /opt/opensearch/bin/opensearch-keystore add --stdin --force s3.client.default.access_key"
  - "printf '%s' '${base64encode(snapshot_repository.secret_key)}' | base64 -d | OPENSEARCH_PATH_CONF=/etc/opensearch/configuration /opt/opensearch/bin/opensearch-keystore add --stdin --force s3.client.default.secret_key"
  - /usr/local/bin/import_snapshot_repository_ca
  - /usr/local/bin/update_snapshot_manifest
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
%{ if try(snapshot_repository.enabled, false) ~}
  - /usr/local/bin/configure_opensearch_snapshot_repository
  - systemctl daemon-reload
  - systemctl enable opensearch-snapshot.timer
  - systemctl start opensearch-snapshot.timer
%{ endif ~}
%{ if try(snapshot_restore.enabled, false) ~}
  - /usr/local/bin/restore_opensearch_snapshot
%{ endif ~}
