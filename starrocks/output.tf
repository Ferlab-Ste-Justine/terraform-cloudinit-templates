output "configuration" {
  description = "Cloudinit compatible starrocks configurations"
  sensitive = true
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
      fe_setup_script = templatefile("${path.module}/setup.sh.tpl", { fe_config = var.fe_config })
      fe_guarded_start_script = var.node_type == "fe" && length(var.fe_config.seed_hosts) > 0 ? templatefile(
        "${path.module}/start-fe-guarded.sh.tpl",
        {
          meta_dir        = var.fe_config.meta_dir
          install_dir     = var.node_type == "cn" ? "be" : var.node_type
          seed_hosts      = var.fe_config.seed_hosts
          initial_cluster = var.fe_config.initial_cluster
          self_host       = var.hosts_file_patch.fqdn
        }
      ) : ""
    }
  )
}
