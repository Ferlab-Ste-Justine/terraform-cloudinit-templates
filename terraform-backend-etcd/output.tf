output "configuration" {
  description = "Cloudinit compatible etcd backend configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      server = var.server
      etcd   = var.etcd
      install_dependencies = var.install_dependencies
    }
  )
}