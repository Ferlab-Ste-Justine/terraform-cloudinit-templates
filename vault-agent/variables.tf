variable "install_dependencies" {
  description = "Whether to install/download application dependencies."
  type        = bool
}

variable "vault_agent" {
  description = "Configuration for Vault Agent"
  type = object({
    auth_method = object({
      config = object({
        role_id   = string
        secret_id = string
      })
    })
    vault_address   = string
    vault_ca_cert   = string
    extra_config    = string
    release_version = string
  })
  default = {
    auth_method = {
      config = {
        role_id   = ""
        secret_id = ""
      }
    }
    vault_address   = ""
    vault_ca_cert   = ""
    extra_config    = ""
    release_version = "1.17.2"
  }
}

variable "external_templates" {
  description = "List of templates provided by external services (e.g., Fluent Bit)"
  type = list(object({
    source_path      = string
    destination_path = string
    secret_path      = string
    secret_key       = string
    command          = optional(string, "")
  }))
  default = []
}

variable "agent_config_path" {
  description = "Path to the directory where Vault Agent configuration files are stored"
  type        = string
  default     = "/etc/vault-agent.d"
}