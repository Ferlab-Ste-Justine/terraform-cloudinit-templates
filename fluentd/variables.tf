variable "install_dependencies" {
  description = "Whether to install/download application dependencies. "
  type        = bool
}

variable "fluentd" {
  description = "Fluentd configurations"
  sensitive   = true
  type = object({
    docker_services = list(object({
      tag                = string
      service            = string
      local_forward_port = number
    }))
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
    }),
    buffer = object({
      customized = bool
      custom_value = string
    })
  })
}