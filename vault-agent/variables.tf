variable "install_dependencies" {
  description = "Whether to install/download application dependencies."
  type        = bool
}

variable "vault_agent" {
  description = "Configuration for Vault Agent"
  type = object({
    enabled             = bool
    auth_method         = object({
      type   = string
      config = object({
        role_id   = string # Content of the role ID file
        secret_id = string # Content of the secret ID file
      })
    })
    vault_address       = string
    vault_ca_cert       = string # Content of the CA certificate file
    templates           = list(object({
      source_path      = string
      destination_path = string
      service_name     = string
      secret_path      = string
      secret_key       = string
    }))
    agent_config        = string
    release_version     = string
  })
}
