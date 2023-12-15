version: v1

address: ${kes_server.address}:7373

admin:
  identity: disabled

tls:
  key: /etc/kes/certs/server.key
  cert: /etc/kes/certs/server.crt
  ca: /etc/kes/certs/ca.crt
  auth: off

cache:
  expiry:
    any: ${kes_server.cache.any}
    unused: ${kes_server.cache.unused}

log:
  error: on
%{ if kes_server.audit_logs ~}
  audit: on
%{ else ~}
  audit: off
%{ endif ~}

policy:
%{ for client in kes_server.clients ~}
  ${client.name}:
    allow:
%{ if client.permissions.create ~}
      - /v1/key/create/${client.key_prefix}*
%{ endif ~}
%{ if client.permissions.delete ~}
      - /v1/key/delete/${client.key_prefix}*
%{ endif ~}
%{ if client.permissions.generate ~}
      - /v1/key/generate/${client.key_prefix}*
%{ endif ~}
%{ if client.permissions.encrypt ~}
      - /v1/key/encrypt/${client.key_prefix}*
%{ endif ~}
%{ if client.permissions.decrypt ~}
      - /v1/key/decrypt/${client.key_prefix}*
%{ endif ~}
    identities:
      - {{client_${client.name}_identity}}
%{ endfor ~}

keystore:
  vault:
    endpoint: "https://${keystore.vault.endpoint}"
    engine: ${keystore.vault.mount}
    version: ${keystore.vault.kv_version}
    prefix: ${keystore.vault.prefix}
    approle:
      engine: ${keystore.vault.approle.mount}
      id: ${keystore.vault.approle.id}
      secret: ${keystore.vault.approle.secret}
      retry: ${keystore.vault.approle.retry_interval}
    tls:
      ca: /etc/kes/certs/vault/ca.crt
    status:
      ping: ${keystore.vault.ping_interval}