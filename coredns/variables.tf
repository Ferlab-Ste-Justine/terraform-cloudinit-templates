variable "install_dependencies" {
  description = "Whether to install/download application dependencies. "
  type        = bool
}

variable "etcd" {
  description = "Parameters to connect to the etcd backend"
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

variable "dns" {
  description = "Parameters for the dns server"
  type        = object({
    dns_bind_addresses = list(string)
    observability_bind_address = string
    nsid = string
    zonefiles_reload_interval = string
    load_balance_records = bool
    alternate_dns_servers = list(string)
  })
  default = {
    dns_bind_addresses = ["0.0.0.0"]
    observability_bind_address = "0.0.0.0"
    nsid = "coredns"
    zonefiles_reload_interval = "3s"
    load_balance_records = true
    alternate_dns_servers = []
  }
}