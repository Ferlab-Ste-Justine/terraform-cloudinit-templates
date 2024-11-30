locals {
  processed_vault_agent = {
    auth_method = {
      type   = var.vault_agent.auth_method.type
      config = var.vault_agent.auth_method.config
    }
    vault_address   = var.vault_agent.vault_address
    vault_ca_cert   = indent(6, var.vault_agent.vault_ca_cert)
    templates       = var.vault_agent.templates
    extra_config    = var.vault_agent.extra_config
    release_version = coalesce(var.vault_agent.release_version, "1.17.2") # Use default if missing
  }
}

output "configuration" {
  description = "Cloudinit compatible Vault Agent configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl",
    {
      install_dependencies = var.install_dependencies
      vault_agent          = local.processed_vault_agent
    }
  )
}
