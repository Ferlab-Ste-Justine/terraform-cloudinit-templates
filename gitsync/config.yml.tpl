log_level: ${log_level}
filesystem:
  path: "${filesystem.path}"
  files_permission: "${filesystem.files_permission}"
  directories_permission: "${filesystem.directories_permission}"
git:
  repo: "${git.repo}"
  ref: "${git.ref}"
  path: "${git.path}"
  auth:
    ssh_key: "/etc/${naming.service}/git/auth/client_ssh_key"
    known_key: "/etc/${naming.service}/git/auth/server_ssh_fingerprint"
%{ if length(git.trusted_gpg_keys) > 0 ~}
  accepted_signatures: "/etc/${naming.service}/git/trusted_gpg_keys"
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