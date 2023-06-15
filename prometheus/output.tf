output "configuration" {
  description = "Cloudinit compatible prometheus configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      prometheus = var.prometheus
    }
  )
}