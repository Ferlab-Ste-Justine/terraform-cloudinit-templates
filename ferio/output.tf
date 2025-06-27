output "configuration" {
  description = "Cloudinit compatible minio configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      ferio                = var.ferio
      minio_services       = var.minio_services
      minio_os_uid         = var.minio_os_uid
    }
  )
}