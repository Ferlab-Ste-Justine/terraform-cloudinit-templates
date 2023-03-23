locals {
  load_balancer_config = templatefile(
    "${path.module}/envoy_config.yml.tpl",
    {
      control_plane = var.control_plane
      load_balancer = var.load_balancer
    }
  )
  control_plane_config = templatefile(
    "${path.module}/control_plane_config.yml.tpl",
    {
      control_plane = var.control_plane
    }
  )
}

output "configuration" {
  description = "Cloudinit compatible transport load balancer configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      control_plane        = var.control_plane
      load_balancer_config = local.load_balancer_config
      control_plane_config = local.control_plane_config
    }
  )
}