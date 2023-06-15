output "configuration" {
  description = "Cloudinit compatible systemd-remote configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      server               = var.server
      install_dependencies = var.install_dependencies
    }
  )
}