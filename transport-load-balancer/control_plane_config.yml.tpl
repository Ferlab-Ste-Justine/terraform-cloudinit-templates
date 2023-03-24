etcd_client:
  prefix: ${control_plane.etcd.key_prefix}
  endpoints:
%{ for endpoint in control_plane.etcd.endpoints ~}
    - "${endpoint}"
%{ endfor ~}
  connection_timeout: "${control_plane.etcd.connection_timeout}"
  request_timeout: "${control_plane.etcd.request_timeout}"
  retries: ${control_plane.etcd.retries}
  auth:
    ca_cert: "/etc/transport-control-plane/etcd/ca.crt"
%{ if control_plane.etcd.client.username == "" ~}
    client_cert: "/etc/transport-control-plane/etcd/client.crt"
    client_key: "/etc/transport-control-plane/etcd/client.key"
%{ else ~}
    password_auth: /etc/transport-control-plane/etcd/auth.yml
%{ endif ~}
server:
  port: ${control_plane.server.port}
  bind_ip: "127.0.0.1"
  max_connections: ${control_plane.server.max_connections}
  keep_alive_time: "${control_plane.server.keep_alive_time}"
  keep_alive_timeout: "${control_plane.server.keep_alive_timeout}"
  keep_alive_min_time: "${control_plane.server.keep_alive_min_time}"
log_level: ${control_plane.log_level}
version_fallback: ${control_plane.version_fallback}