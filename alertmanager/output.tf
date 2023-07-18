output "configuration" {
  description = "Cloudinit compatible alertmanager configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      alertmanager         = var.alertmanager
    }
  )
}