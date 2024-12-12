snapshot_path: "/var/lib/etcd-restore/snapshots/snapshot"
%{ if encryption_key != "" ~}
encryption_key_path: "/etc/etcd/restore/master.key"
%{ endif ~}
s3_client:
  objects_prefix: "${s3.object_prefix}"
  endpoint: "${s3.endpoint}"
  bucket: "${s3.bucket}"
  auth:
%{ if s3.ca_cert != "" ~}
    ca_cert: "/etc/etcd/restore/ca.crt"
%{ endif ~}
    key_auth: "/etc/etcd/restore/s3_keys.yml"
  region: "${s3.region}"
  connection_timeout: "300s"
  request_timeout: "300s"
log_level: "info"