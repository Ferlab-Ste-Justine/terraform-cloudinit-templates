variable "kes_server" {
  description = "Kes server parameters"
  type = object({
    address      = string
    tls          = object({
      server_cert = string
      server_key  = string
      ca_cert     = string
    })
    clients      = list(object({
      name = string
      key_prefix = string
      permissions = object({
        list_all = bool
        create   = bool
        delete   = bool
        generate = bool
        encrypt  = bool
        decrypt  = bool
      })
      client_cert = string
    }))
    cache = object({
      any    = string
      unused = string
    })
    audit_logs = bool
  })
}

variable "keystore" {
  description = "Kes server keystore backend parameters"
  type = object({
    vault = object({
      endpoint       = string
      mount          = string
      kv_version     = string
      prefix         = string
      approle        = object({
        mount          = string
        id             = string
        secret         = string
        retry_interval = string
      })
      ca_cert        = string
      ping_interval  = string
    })
  })
} 

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type = bool
  default = true
}