locals {
  haproxy_config = templatefile(
    "${path.module}/lb-haproxy.cfg.tpl",
    {
      tls     = var.tls
      haproxy = var.haproxy
    }
  )
}

output "configuration" {
  description = "Cloudinit compatible vault load balancer configurations"
  sensitive   = true
  value       = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      tls                  = var.tls
      haproxy_config       = local.haproxy_config
    }
  )
}