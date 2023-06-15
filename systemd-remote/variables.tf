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

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type        = bool
}