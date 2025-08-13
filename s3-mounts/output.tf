output "configuration" {
  description = "Cloudinit compatible S3 mounts configurations"
  sensitive   = true
  value       = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      mounts               = var.mounts
    }
  )
}
