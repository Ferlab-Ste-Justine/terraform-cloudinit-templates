locals {
  processed_vault_agent = {
    auth_method = {
      type   = var.vault_agent.auth_method.type
      config = var.vault_agent.auth_method.config
    }
    vault_address   = var.vault_agent.vault_address
    vault_ca_cert   = indent(6, var.vault_agent.vault_ca_cert)
    templates       = var.vault_agent.templates
    agent_config    = var.vault_agent.agent_config
    release_version = var.vault_agent.release_version
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
