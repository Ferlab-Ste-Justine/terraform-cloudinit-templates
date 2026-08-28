output "configuration" {
  description = "Cloudinit compatible metrics exporter reverse proxy configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies   = var.install_dependencies
      cpu_architecture       = var.cpu_architecture == "amd64" ? "x86_64" : "aarch_64"
      reverse_proxy          = var.reverse_proxy
      envoy_config_core      = templatefile(
        "${path.module}/envoy_config_core.yml.tpl",
        {
          reverse_proxy = var.reverse_proxy
        }
      )
      envoy_config_clusters  = templatefile(
        "${path.module}/envoy_config_clusters.yml.tpl",
        {
          reverse_proxy = var.reverse_proxy
        }
      )
      envoy_config_listeners = templatefile(
        "${path.module}/envoy_config_listeners.yml.tpl",
        {
          reverse_proxy = var.reverse_proxy
        }
      )
    }
  )
}