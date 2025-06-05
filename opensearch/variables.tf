variable "opensearch_host" {
  description = "Opensearch host configurations"
  type = object({
    bind_ip             = string
    extra_http_bind_ips = list(string)
    bootstrap_security  = bool
    host_name           = string
    initial_cluster     = bool
    manager             = bool
  })
}

variable "opensearch_cluster" {
  description = "Opensearch cluster wide configurations"
  type = object({
    auth_dn_fields      = object({
      admin_common_name = string
      node_common_name  = string
      organization      = string
    })
    basic_auth_enabled  = bool
    cluster_name        = string
    seed_hosts          = list(string)
    verify_domains      = bool
  })
}

variable "tls" {
  description = "Tls parameters"
  type = object({
    server_cert = string
    server_key  = string
    ca_cert     = string
    admin_cert  = string
    admin_key   = string
  })
}

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type = bool
  default = true
}