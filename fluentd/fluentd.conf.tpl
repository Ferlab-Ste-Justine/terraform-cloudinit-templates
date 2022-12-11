<system>
  Log_Level info
</system>

%{ for val in fluentd.systemd_services ~}
<source>
  @type systemd
  tag ${val.tag}
  path /var/log/journal
  matches [{ "_SYSTEMD_UNIT": "${val.service}.service" }]
  read_from_head true

  <storage>
    @type local
    path /opt/fluentd-state/${val.service}-cursor.json
  </storage>
</source>
%{ endfor ~}

%{ for val in fluentd.docker_services ~}
<source>
  @type forward
  tag ${val.tag}
  port ${val.local_forward_port}
  bind 127.0.01
</source>


<filter ${val.tag}>
  @type record_transformer
  <record>
    hostname "#{Socket.gethostname}"
    application ${val.service}
  </record>
</filter>
%{ endfor ~}

<match *>
  @type forward
  transport tls
  tls_insecure_mode false
  tls_allow_self_signed_cert false
  tls_verify_hostname true
  tls_cert_path /opt/fluentd_ca.crt
  send_timeout 20
  connect_timeout 20
  hard_timeout 20
  recover_wait 10
  expire_dns_cache 5
  dns_round_robin true

  <server>
    host ${fluentd.forward.domain}
    port ${fluentd.forward.port}
  </server>

  <security>
    self_hostname ${fluentd.forward.hostname}
    shared_key ${fluentd.forward.shared_key}
  </security>

  ${indent(2, fluentd_buffer_conf)}
</match>