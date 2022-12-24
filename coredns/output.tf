locals {
  corefile_conf = templatefile(
    "${path.module}/Corefile.tpl", 
    {
      dns = var.dns
    }
  )
}

output "configuration" {
  description = "Cloudinit compatible coredns configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      corefile = local.corefile_conf
      etcd = var.etcd
    }
  )
}