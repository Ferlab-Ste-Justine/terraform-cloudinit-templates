output "configuration" {
  description = "Cloudinit compatible smrt-link configurations"
  value       = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies    = var.install_dependencies
      domain_name             = var.domain_name
      tls_custom              = var.tls_custom
      user                    = var.user
      revio                   = var.revio
      release_version         = var.release_version
      install_lite            = var.install_lite
      workers_count           = var.workers_count
      keycloak_user_passwords = var.keycloak_user_passwords
      keycloak_users          = var.keycloak_users
      smtp                    = var.smtp
    }
  )
}
