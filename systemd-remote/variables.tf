variable "server" {
  description = "Parameters for the grpc server exposed by systemd-remote"
  type = object({
    address = string
    port    = number
    tls     = object({
      ca_certificate     = string
      server_certificate = string
      server_key         = string
    })
  })
}

variable "client" {
  description = "Parameters for the service that will push changes to systemd-remote"
  type = object({
    tls = object({
      ca_certificate     = string
      client_certificate = string
      client_key         = string
    })
    etcd = object({
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
  })
}

variable "sync_directory" {
  description = "Directory where configuration files from the etcd server will be synchronized"
  type        = string
}

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type        = bool
}