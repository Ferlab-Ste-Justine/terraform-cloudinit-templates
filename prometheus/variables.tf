variable "install_dependencies" {
  description = "Whether to install/download application dependencies. "
  type        = bool
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