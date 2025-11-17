locals {
  opensearch_audit_conf = var.opensearch_cluster.audit == null ? null : merge(
    var.opensearch_cluster.audit,
    {
      enabled = try(var.opensearch_cluster.audit.enabled, false)
    }
  )

  opensearch_initial_cluster_manager_nodes = (
    try(length(var.opensearch_cluster.initial_cluster_manager_nodes), 0) > 0 ?
    var.opensearch_cluster.initial_cluster_manager_nodes :
    var.opensearch_cluster.seed_hosts
  )

  opensearch_cluster_with_defaults = merge(
    var.opensearch_cluster,
    local.opensearch_audit_conf == null ? {} : {
      audit = local.opensearch_audit_conf
    },
    {
      initial_cluster_manager_nodes = local.opensearch_initial_cluster_manager_nodes
    }
  )

  opensearch_host_is_cluster_manager = var.opensearch_host.cluster_manager

  opensearch_host_with_role = merge(
    var.opensearch_host,
    {
      cluster_manager = local.opensearch_host_is_cluster_manager
    }
  )

  opensearch_bootstrap_conf = templatefile(
    "${path.module}/opensearch.yml.tpl",
    {
      opensearch_cluster = local.opensearch_cluster_with_defaults
      opensearch_host    = local.opensearch_host_with_role
    }
  )
  opensearch_runtime_conf = templatefile(
    "${path.module}/opensearch.yml.tpl",
    {
      opensearch_cluster = local.opensearch_cluster_with_defaults
      opensearch_host = merge(
        local.opensearch_host_with_role,
        {
          initial_cluster = false
        }
      )
    }
  )
  opensearch_security_conf = {
    config = templatefile(
      "${path.module}/opensearch_security/config.yml.tpl",
      {
        opensearch_cluster = local.opensearch_cluster_with_defaults
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
      opensearch_cluster        = local.opensearch_cluster_with_defaults
      opensearch_host           = local.opensearch_host_with_role
      tls                       = var.tls
      opensearch_bootstrap_conf = local.opensearch_bootstrap_conf
      opensearch_runtime_conf   = local.opensearch_runtime_conf
      opensearch_security_conf  = local.opensearch_security_conf
    }
  )
}
