variable "install_dependencies" {
  description = "Whether to install/download application dependencies. "
  type        = bool
}

variable "etcd" {
  description = "Parameters to connect to the etcd backend"
  type        = object({
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

variable "prometheus" {
  description = "Prometheus configurations"
  type = object({
      web = object({
        external_url = string
        max_connections = number
        read_timeout = string
      })
      retention = object({
        time = string
        size = string
      })
  })
}