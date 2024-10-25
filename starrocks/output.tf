output "configuration" {
  description = "Cloudinit compatible starrocks configurations"
  value       = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      timezone             = var.timezone
      release_version      = var.release_version
      node_type            = var.node_type
      is_fe_leader         = var.is_fe_leader
      fe_leader_node       = var.fe_leader_node
      fe_follower_nodes    = var.fe_follower_nodes
      be_nodes             = var.be_nodes
      root_password        = var.root_password
    }
  )
}
