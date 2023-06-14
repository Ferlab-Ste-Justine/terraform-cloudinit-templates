log_level: ${log_level}
filesystem:
  path: "${filesystem.path}"
  files_permission: "${filesystem.files_permission}"
  directories_permission: "${filesystem.directories_permission}"
etcd_client:
  prefix: "${etcd.key_prefix}"
  endpoints:
%{ for endpoint in etcd.endpoints ~}
    - "${endpoint}"
%{ endfor ~}
  connection_timeout: "${etcd.connection_timeout}"
  request_timeout: "${etcd.request_timeout}"
  retry_interval: "${etcd.retry_interval}"
  retries: ${etcd.retries}
  auth:
    ca_cert: "/etc/${naming.service}/etcd/ca.crt"
%{ if etcd.auth.client_certificate != "" ~}
    client_cert: "/etc/${naming.service}/etcd/client.crt"
    client_key: "/etc/${naming.service}/etcd/client.key"
%{ else ~}
    password_auth: /etc/${naming.service}/etcd/password.yml
%{ endif ~}
%{ if length(notification_command.command) > 0 ~}
notification_command_retries: ${notification_command.retries}
notification_command:
%{ for command_part in notification_command.command ~}
  - "${command_part}"
%{ endfor ~}
%{ endif ~}
%{ if length(grpc_notifications) > 0 ~}
grpc_notifications:
%{ for idx, grpc_notification in grpc_notifications ~}
  - endpoint: "${grpc_notification.endpoint}"
    filter: "${grpc_notification.filter}"
%{ if grpc_notification.trim_key_path ~}
    trim_key_path: true
%{ else ~}
    trim_key_path: false
%{ endif ~}
    max_chunk_size: ${grpc_notification.max_chunk_size}
    connection_timeout: "${grpc_notification.connection_timeout}"
    request_timeout: "${grpc_notification.request_timeout}"
    retry_interval: "${grpc_notification.retry_interval}"
    retries: ${grpc_notification.retries}
    auth:
      ca_cert: "/etc/${naming.service}/grpc/endpoint${idx}/ca.crt"
      client_cert: "/etc/${naming.service}/grpc/endpoint${idx}/client.crt"
      client_key: "/etc/${naming.service}/grpc/endpoint${idx}/client.key"
%{ endfor ~}
%{ endif ~}