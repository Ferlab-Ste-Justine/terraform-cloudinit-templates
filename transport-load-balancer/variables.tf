variable "install_dependencies" {
  description = "Whether to install/download application dependencies. "
  type        = bool
}

variable "control_plane" {
  description = "Properties of the control plane"
  type = object({
    log_level        = string
    version_fallback = string
    server           = object({
      port                = number
      max_connections     = number
      keep_alive_time     = string
      keep_alive_timeout  = string
      keep_alive_min_time = string
    })
    etcd             = object({
      key_prefix         = string
      endpoints          = list(string)
      connection_timeout = string
      request_timeout    = string
      retries            = number
      ca_certificate     = string
      client             = object({
        certificate = string
        key         = string
        username    = string
        password    = string
      })
    })
  })
}

variable "load_balancer" {
  description = "Properties of the load balancer"
  type = object({
    cluster   = string
    node_id   = string
    log_level = string
  })
}