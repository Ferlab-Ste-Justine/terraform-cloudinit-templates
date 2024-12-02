locals {
  processed_vault_agent = {
    auth_method = {
      config = var.vault_agent.auth_method.config
    }
    vault_address   = var.vault_agent.vault_address
    vault_ca_cert   = indent(6, var.vault_agent.vault_ca_cert)
    extra_config    = var.vault_agent.extra_config
    release_version = coalesce(var.vault_agent.release_version, "1.17.2") # Use default if missing
  }

  all_templates = var.external_templates
}

output "configuration" {
  description = "Cloudinit compatible Vault Agent configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl",
    {
      install_dependencies = var.install_dependencies
      vault_agent          = local.processed_vault_agent
      external_templates   = local.all_templates
      agent_config_path    = var.agent_config_path
    }
  )
}

