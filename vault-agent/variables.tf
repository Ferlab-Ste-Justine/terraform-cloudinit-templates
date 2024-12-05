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
  }
}