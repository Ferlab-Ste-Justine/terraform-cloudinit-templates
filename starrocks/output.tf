output "configuration" {
  description = "Cloudinit compatible starrocks configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl",
    {
      install_dependencies = var.install_dependencies
      timezone             = var.timezone
      hosts_file_patch     = var.hosts_file_patch
      release_version      = var.release_version
      install              = var.install
      node_type            = var.node_type
      fe_config            = var.fe_config
      be_storage_root_path = var.be_storage_root_path
      cn_config            = var.cn_config
      secrets_manager      = var.secrets_manager
      data_volume          = var.data_volume
    }
  )
}
