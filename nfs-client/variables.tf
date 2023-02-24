variable "proxy" {
  description = "Parameters for proxy"
  type = object({
    client_name     = string
    nameserver_ips  = list(string)
    max_connections = number
    idle_timeout    = string
  })
}

variable "nfs_server" {
  description = "Parameters specific to the nfs server"
  type = object({
    domain = string
    port   = string
  })
}

variable "tls" {
  description = "Tls parameters"
  type = object({
    client_cert = string
    client_key  = string
    ca_cert     = string
  })
}

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type = bool
  default = true
}