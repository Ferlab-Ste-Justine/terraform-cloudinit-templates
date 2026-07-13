output "configuration" {
  description = "Cloudinit compatible starrocks configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl",
    {
      dependencies         = var.dependencies
      timezone             = var.timezone
      hosts_file_patch     = var.hosts_file_patch
      node_type            = var.node_type
      install_dir          = var.node_type == "cn" ? "be" : var.node_type
      fe_config            = var.fe_config
      be_storage_root_path = var.be_storage_root_path
      cn_config            = var.cn_config
      ranger_audit_conf    = var.fe_config.ranger != null ? file("${path.module}/ranger-starrocks-audit.xml") : ""
      ranger_security_conf = var.fe_config.ranger != null ? templatefile(
        "${path.module}/ranger-starrocks-security.xml.tpl",
        {
          host          = var.fe_config.ranger.host
          sync_username = var.fe_config.ranger.sync_username
          sync_password = var.fe_config.ranger.sync_password
        }
      ) : ""
    }
  )
}
