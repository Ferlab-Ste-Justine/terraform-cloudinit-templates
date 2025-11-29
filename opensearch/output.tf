locals {
  opensearch_initial_cluster_manager_nodes = (
    length(var.opensearch_cluster.initial_cluster_manager_nodes) > 0 ?
    var.opensearch_cluster.initial_cluster_manager_nodes :
    var.opensearch_cluster.seed_hosts
  )

  opensearch_cluster_with_defaults = merge(
    var.opensearch_cluster,
    {
      initial_cluster_manager_nodes = local.opensearch_initial_cluster_manager_nodes
    }
  )

  opensearch_bootstrap_conf = templatefile(
    "${path.module}/opensearch.yml.tpl",
    {
      opensearch_cluster = local.opensearch_cluster_with_defaults
      opensearch_host    = var.opensearch_host
    }
  )
  opensearch_runtime_conf = templatefile(
    "${path.module}/opensearch.yml.tpl",
    {
      opensearch_cluster = local.opensearch_cluster_with_defaults
      opensearch_host = merge(
        var.opensearch_host,
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
    audit = templatefile(
      "${path.module}/opensearch_security/audit.yml.tpl",
      {
        opensearch_cluster = local.opensearch_cluster_with_defaults
      }
    )
  }
  
  # Remove sensitive fields (access_key, secret_key) from snapshot_repository for output
  # These credentials should be managed securely and not exposed in Terraform state/outputs
  snapshot_repository_sanitized = {
    for k, v in var.snapshot_repository :
    k => v
    if k != "access_key" && k != "secret_key"
  }
  
  # snapshot_restore doesn't contain sensitive fields, but we sanitize it for consistency
  snapshot_restore_sanitized = var.snapshot_restore
}

output "configuration" {
  description = "Cloudinit compatible opensearch configurations"
  # Mark as sensitive because the cloud-init configuration contains S3 credentials
  # embedded in scripts. While these are needed for functionality, they should not
  # be exposed in Terraform CLI output or logs.
  sensitive = true
  value = templatefile(
    "${path.module}/user_data.yaml.tpl",
    {
      install_dependencies      = var.install_dependencies
      opensearch_cluster        = local.opensearch_cluster_with_defaults
      opensearch_host           = var.opensearch_host
      tls                       = var.tls
      opensearch_bootstrap_conf = local.opensearch_bootstrap_conf
      opensearch_runtime_conf   = local.opensearch_runtime_conf
      opensearch_security_conf  = local.opensearch_security_conf
      snapshot_repository       = var.snapshot_repository
      snapshot_restore          = var.snapshot_restore
      snapshot_timer            = var.snapshot_timer
    }
  )
}
