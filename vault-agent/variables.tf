variable "install_dependencies" {
  description = "Whether to install/download application dependencies."
  type        = bool
}

variable "vault_agent" {
  description = "Configuration for Vault Agent"
  type = object({
    auth_method         = object({
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
      secret_path      = string
      secret_key       = string
      command          = string # Optional command for this template
    }))
    extra_config        = string
    release_version     = string
  })
  default = {
    auth_method = {
      config = {
        role_id   = ""
        secret_id = ""
      }
    }
    vault_address = ""
    vault_ca_cert = ""
    templates = []
    extra_config = ""
    release_version = "1.17.2"
  }
}