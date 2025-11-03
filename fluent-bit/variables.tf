variable "install_dependencies" {
  description = "Whether to install/download application dependencies. "
  type        = bool
}

variable "fluentbit" {
  description = "Fluent-bit configurations"
  sensitive   = true
  type = object({
    metrics = object({
      enabled = bool
      port    = number
    })
    systemd_services = list(object({
      tag     = string
      service = string
    }))
    log_files = list(object({
      tag            = string
      path           = string
      read_from_head = bool
    }))
    forward = object({
      domain    = string
      port      = number
      hostname  = string
      shared_key = string
      ca_cert   = string
    })
    http_input = optional(object({
      enabled = bool
      listen  = string
      port    = number
      tag     = string
      path    = string 
    }), null)
  })
}

variable "dynamic_config" {
  description = "Settings for dynamic configuration"
  type = object({
    enabled         = bool
    entrypoint_path = string
  })
  default = {
    enabled         = false
    entrypoint_path = ""
  }
}

variable "vault_agent_integration" {
  description = "Configuration for integrating Fluent Bit with Vault Agent"
  type = object({
    enabled           = bool
    secret_path       = string
    agent_config_path = string
    config_name_prefix = string
  })
  default = {
    enabled           = false
    secret_path       = ""
    agent_config_path = "/etc/vault-agent.d"
    config_name_prefix = "fluentbit"
  }
}
