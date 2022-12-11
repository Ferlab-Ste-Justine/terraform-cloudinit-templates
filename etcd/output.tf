locals {
  etcd_initial_cluster = {
    token   = var.etcd_initial_cluster.token
    state   = var.etcd_initial_cluster.is_initializing ? "new" : "existing"
    members = join(
      ",",
      [for elem in var.etcd_initial_cluster.members: "${elem["name"]}=https://${elem["ip"]}:2380"]
    )
  }
}

output "configuration" {
  description = "Cloudinit compatible fluentd configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      etcd_host            = var.etcd_host
      etcd_cluster         = var.etcd_cluster
      etcd_initial_cluster = local.etcd_initial_cluster
      tls                  = var.tls
    }
  )
}