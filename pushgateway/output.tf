output "configuration" {
  description = "Cloudinit compatible pushgateway configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      pushgateway          = var.pushgateway
    }
  )
}