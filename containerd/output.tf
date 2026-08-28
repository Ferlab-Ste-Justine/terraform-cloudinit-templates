output "configuration" {
  description = "Cloudinit compatible containerd configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      cpu_architecture     = var.cpu_architecture
      buildkit_enabled     = var.buildkit_enabled
    }
  )
}