locals {
  envoy_config_core = templatefile(
    "${path.module}/envoy_config_core.yml.tpl",
    {
      proxy = var.proxy
    }
  )
  envoy_config_listeners = templatefile(
    "${path.module}/envoy_config_listeners.yml.tpl",
    {
      proxy = var.proxy
    }
  )
  envoy_config_clusters = templatefile(
    "${path.module}/envoy_config_clusters.yml.tpl",
    {
      proxy = var.proxy
      nfs_server = var.nfs_server
    }
  )
}

output "configuration" {
  description = "Cloudinit nfs tunnel client configuration"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies      = var.install_dependencies
      tls                       = var.tls
      envoy_config_core         = local.envoy_config_core
      envoy_config_listeners    = local.envoy_config_listeners
      envoy_config_clusters     = local.envoy_config_clusters
    }
  )
}