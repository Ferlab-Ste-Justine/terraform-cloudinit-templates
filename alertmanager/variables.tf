variable "install_dependencies" {
  description = "Whether to install/download application dependencies. "
  type        = bool
}

variable "alertmanager" {
  description = "Alert Manager configurations"
  type = object({
    external_url = string
    data_retention = string
    peers = list(string)
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
