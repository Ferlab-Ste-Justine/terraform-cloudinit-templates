variable "install_dependencies" {
  description = "Whether to install/download application dependencies."
  type        = bool
}

variable "tls" {
  description = "Configuration for a secure vault communication over tls"
  type        = object({
    ca_certificate     = string
    client_certificate = string
    client_key         = string
    client_auth        = bool
  })
}

variable "haproxy" {
  description = "Haproxy configuration parameters"
  sensitive   = true
  type        = object({
    vault_nodes_max_count = number
    vault_nameserver_ips  = list(string)
    vault_domain          = string
    timeouts              = object({
      connect = string
      check   = string
      idle    = string
    })
  })
}