output "configuration" {
  description = "Cloudinit compatible vault configurations"
  value       = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      hostname             = var.hostname
      release_version      = var.release_version
      tls                  = var.tls
      etcd_backend         = var.etcd_backend
    }
  )
}