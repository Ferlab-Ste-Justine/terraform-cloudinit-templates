global
  user www-data
  group www-data
  log stdout local0 info

defaults
  mode tcp
  log global
  timeout client ${haproxy.timeouts.idle}
  timeout server ${haproxy.timeouts.idle}
  timeout connect ${haproxy.timeouts.connect}
  timeout check ${haproxy.timeouts.check}

resolvers internal_dns
%{ for ip in haproxy.vault_nameserver_ips ~}
  nameserver dns_${ip} ${ip}:53
%{ endfor ~}
  resolve_retries      3
  timeout retry        1s
  hold other           5s
  hold refused         5s
  hold nx              5s
  hold timeout         5s
  hold valid           5s

backend vault_servers
  mode tcp
  balance roundrobin
  option ssl-hello-chk
  option httpchk
  http-check connect port 8200 ssl
  http-check send meth GET uri /v1/sys/health
  http-check expect status 200
  default-server inter 1000ms rise 1 fall 1
%{ if tls.client_auth ~}
  server-template vault_nodes ${haproxy.vault_nodes_max_count} ${haproxy.vault_domain}:8200 check check-ssl verify required ca-file /opt/vault/ca.crt crt /opt/vault/client.pem resolvers internal_dns init-addr none
%{ else ~}
  server-template vault_nodes ${haproxy.vault_nodes_max_count} ${haproxy.vault_domain}:8200 check check-ssl verify required ca-file /opt/vault/ca.crt resolvers internal_dns init-addr none
%{ endif ~}

frontend vault_servers
  mode tcp
  bind *:443
  default_backend vault_servers