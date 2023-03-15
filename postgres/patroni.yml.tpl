scope: ${patroni.scope}
namespace: ${patroni.namespace}
name: ${patroni.name}

restapi:
  listen: 0.0.0.0:4443
  connect_address: ${advertise_ip}:4443
  certfile: /etc/patroni/tls/api-server.crt
  keyfile: /etc/patroni/tls/api-server.key
  cafile: /etc/patroni/tls/api-ca.crt
  verify_client: required

ctl:
  insecure: false
  certfile: /etc/patroni/tls/api-client.crt
  keyfile: /etc/patroni/tls/api-client.key
  cacert: /etc/patroni/tls/api-ca.crt

etcd3:
  protocol: https
  cacert: /etc/patroni/tls/etcd-ca.crt
  username: ${etcd.username}
  password: ${etcd.password}
  hosts:
%{ for endpoint in etcd.endpoints ~}
    - ${endpoint}
%{ endfor ~}

bootstrap:
  dcs:
    ttl: ${patroni.ttl}
    loop_wait: ${patroni.loop_wait}
    retry_timeout: ${patroni.retry_timeout}
    master_start_timeout: ${patroni.master_start_timeout}
    master_stop_timeout: ${patroni.master_stop_timeout}
    synchronous_mode: true
    synchronous_mode_strict: true
    synchronous_node_count: ${patroni.synchronous_node_count}
    postgresql:
      use_pg_rewind: false
      use_slots: true
      parameters:
        ssl: on
        ssl_cert_file: /etc/postgres/tls/server.crt
        ssl_key_file: /etc/postgres/tls/server.key
        log_directory: /var/log/postgresql
%{ for param in postgres.params ~}
        ${param.key}: "${param.value}"
%{ endfor ~}

  initdb:
    - encoding: UTF8
    - data-checksums
    - locale: C

postgresql:
  listen: 0.0.0.0:5432
  connect_address: ${advertise_ip}:5432
  data_dir: /var/lib/postgresql/14/data
  bin_dir: /usr/lib/postgresql/14/bin
  pgpass: /etc/patroni/.pgpass
  pg_hba:
    - hostssl all all 0.0.0.0/0 scram-sha-256
    - hostssl replication replicator 0.0.0.0/0 scram-sha-256
  authentication:
    replication:
      username: replicator
      password: ${postgres.replicator_password}
      sslmode: verify-full
      sslrootcert: /etc/postgres/tls/ca.crt
    superuser:
      username: postgres
      password: ${postgres.superuser_password}
      sslmode: verify-full
      sslrootcert: /etc/postgres/tls/ca.crt

watchdog:
  mode: required
  device: /dev/watchdog
  safety_margin: ${patroni.watchdog_safety_margin}

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false