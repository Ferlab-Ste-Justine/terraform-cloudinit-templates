locals {
  patroni_conf = templatefile(
    "${path.module}/patroni.yml.tpl",
    {
      postgres     = var.postgres
      patroni      = var.patroni
      etcd         = var.etcd
      advertise_ip = var.advertise_ip
    }
  )
}

output "configuration" {
  description = "Cloudinit compatible opensearch configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      postgres             = var.postgres
      patroni              = var.patroni
      etcd                 = var.etcd
      patroni_conf         = local.patroni_conf
    }
  )
}