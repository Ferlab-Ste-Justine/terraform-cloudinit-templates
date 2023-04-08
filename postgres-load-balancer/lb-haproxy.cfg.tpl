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
%{ for ip in haproxy.postgres_nameserver_ips ~}
  nameserver dns_${ip} ${ip}:53
%{ endfor ~}
  resolve_retries      3
  timeout retry        1s
  hold other           5s
  hold refused         5s
  hold nx              5s
  hold timeout         5s
  hold valid           5s

backend postgres_servers
  mode tcp
  balance roundrobin
  option httpchk
  http-check connect port 4443 ssl
  http-check send meth OPTIONS uri /master
  http-check expect status 200
  default-server inter 1000ms rise 1 fall 1
  server-template postgres_nodes ${haproxy.postgres_nodes_max_count} ${haproxy.postgres_domain}:5432 check check-ssl verify required ca-file /opt/patroni/ca.pem crt /opt/patroni/client.pem resolvers internal_dns init-addr none

frontend postgres_servers
  mode tcp
  bind *:5432
  default_backend postgres_servers