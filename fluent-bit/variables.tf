variable "install_dependencies" {
  description = "Whether to install/download application dependencies. "
  type        = bool
}

variable "etcd" {
  description = "Parameters to connect to an optional etcd backend to auto update"
  type        = object({
    enabled = bool
    key_prefix = string
    endpoints = list(string)
    ca_certificate = string
    client = object({
      certificate = string
      key = string
      username = string
      password = string
    })
  })
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
    forward = object({
      domain = string
      port = number
      hostname = string
      shared_key = string
      ca_cert = string
    })
  })
}