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
    }
  )
  nfs_exports = templatefile(
    "${path.module}/exports.tpl",
    {
      nfs_configs = var.nfs_configs
    }
  )
  nfs_dirs = [for nfs_config in var.nfs_configs : nfs_config.path]
}

output "configuration" {
  description = "Cloudinit nfs tunnel client configuration"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies      = var.install_dependencies
      proxy                     = var.proxy
      envoy_config_core         = local.envoy_config_core
      envoy_config_listeners    = local.envoy_config_listeners
      envoy_config_clusters     = local.envoy_config_clusters
      nfs_exports               = local.nfs_exports
      nfs_dirs                  = local.nfs_dirs
    }
  )
}