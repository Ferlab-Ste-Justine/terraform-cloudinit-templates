output "configuration" {
  description = "Cloudinit compatible starrocks configurations"
  value       = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      release_version      = var.release_version
      node_type            = var.node_type
      is_fe_leader         = var.is_fe_leader
      fe_leader_fqdn       = var.fe_leader_fqdn
      fe_follower_fqdns    = var.fe_follower_fqdns
      be_fqdns             = var.be_fqdns
      root_password        = var.root_password
    }
  )
}
