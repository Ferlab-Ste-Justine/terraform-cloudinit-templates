output "configuration" {
  description = "Cloudinit compatible node exporter configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
    }
  )
}