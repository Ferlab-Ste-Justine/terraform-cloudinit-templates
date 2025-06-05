locals {
  opensearch_bootstrap_conf = templatefile(
    "${path.module}/opensearch.yml.tpl",
    {
      opensearch_cluster = var.opensearch_cluster
      opensearch_host    = var.opensearch_host
    }
  )
  opensearch_runtime_conf = templatefile(
    "${path.module}/opensearch.yml.tpl",
    {
      opensearch_cluster = var.opensearch_cluster
      opensearch_host    = {
        bind_ip             = var.opensearch_host.bind_ip
        extra_http_bind_ips = var.opensearch_host.extra_http_bind_ips
        bootstrap_security  = var.opensearch_host.bootstrap_security
        host_name           = var.opensearch_host.host_name
        initial_cluster     = false
        manager             = var.opensearch_host.manager
      }
    }
  )
  opensearch_security_conf = {
    config = templatefile(
      "${path.module}/opensearch_security/config.yml.tpl",
      {
        opensearch_cluster = var.opensearch_cluster
      }
    )
  }
}

output "configuration" {
  description = "Cloudinit compatible opensearch configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies      = var.install_dependencies
      opensearch_cluster        = var.opensearch_cluster
      opensearch_host           = var.opensearch_host
      tls                       = var.tls
      opensearch_bootstrap_conf = local.opensearch_bootstrap_conf
      opensearch_runtime_conf   = local.opensearch_runtime_conf
      opensearch_security_conf  = local.opensearch_security_conf
    }
  )
}