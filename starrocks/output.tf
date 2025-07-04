output "configuration" {
  description = "Cloudinit compatible starrocks configurations"
  value       = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      timezone             = var.timezone
      fqdn_patch           = var.fqdn_patch
      release_version      = var.release_version
      node_type            = var.node_type
      fe_config            = var.fe_config
      be_storage_root_path = var.be_storage_root_path
    }
  )
}
