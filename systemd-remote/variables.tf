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
    auth    = object({
      username = string
      password = string
    })
  })
}

variable "etcd" {
  description = "Parameters for the etcd connection to fetch the configurations"
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

variable "sync_directory" {
  description = "Directory where configuration files from the etcd server will be synchronized"
  type        = string
}

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type        = bool
}