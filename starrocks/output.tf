output "configuration" {
  description = "Cloudinit compatible starrocks configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl",
    {
      dependencies         = var.dependencies
      timezone             = var.timezone
      hosts_file_patch     = var.hosts_file_patch
      node_type            = var.node_type
      fe_config            = var.fe_config
      be_storage_root_path = var.be_storage_root_path
      cn_config            = var.cn_config
    }
  )
}
