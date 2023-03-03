output "configuration" {
  description = "Cloudinit compatible S3 backup configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      object_store = var.object_store
      backup = var.backup
    }
  )
}