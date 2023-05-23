variable "server" {
  description = "Parameters for the http server implementing terraform's http backend api"
  type = object({
    address = string
    port    = number
    tls     = object({
      ca_certificate     = string
      server_certificate = string
      server_key         = string
    })
    auth    = object({
      username = string
      password = string
    })
  })
}

variable "etcd" {
  description = "Parameters for the connection to the backing etcd store"
  type        = object({
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

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type        = bool
}