locals {
  restore_conf = templatefile(
    "${path.module}/restore_config.yml.tpl",
    {
      s3 = var.restore.s3,
      encryption_key = var.restore.encryption_key
    }
  )
  members = join(
    ",",
    [for elem in var.etcd_initial_cluster.members: "${elem["name"]}=https://${elem["ip"]}:2380"]
  )
  etcd_backup_params = join(" ", concat(
    [
      "--config=/etc/etcd/restore/config.yml",
      "--data-dir=/var/lib/etcd",
      "--name=\"${var.etcd_initial_cluster.name}\"",
      "--initial-cluster=\"${local.members}\"",
      "--initial-cluster-token=\"${var.etcd_initial_cluster.token}\"",
      "--initial-advertise-peer-urls=https://${var.etcd_initial_cluster.ip}:2380"
    ],
    var.restore.backup_timestamp == "" ? [] : [
      "--backup-timestamp ${var.restore.backup_timestamp}"
    ]
  ))
}

output "configuration" {
  description = "Cloudinit compatible fluentd configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      restore_conf         = local.restore_conf
      restore              = var.restore
      etcd_backup_params   = local.etcd_backup_params 
    }
  )
}