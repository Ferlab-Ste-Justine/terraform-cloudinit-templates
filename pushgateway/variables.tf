variable "install_dependencies" {
  description = "Whether to install/download application dependencies. "
  type        = bool
}

variable "pushgateway" {
  description = "Push Gateway configurations"
  type = object({
    tls = object({
      ca_cert     = string
      server_cert = string
      server_key  = string
    })
    basic_auth = object({
      username        = string
      hashed_password = string
    })
  })
}
