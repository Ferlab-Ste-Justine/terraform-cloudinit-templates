variable "opensearch_host" {
  description = "Opensearch host configurations"
  type = object({
    bind_ip             = string
    extra_http_bind_ips = list(string)
    bootstrap_security  = bool
    host_name           = string
    initial_cluster     = bool
    cluster_manager     = bool
  })
}

variable "opensearch_cluster" {
  description = "Opensearch cluster wide configurations"
  type = object({
    auth_dn_fields = object({
      admin_common_name = string
      node_common_name  = string
      organization      = string
    })
    basic_auth_enabled            = bool
    cluster_name                  = string
    seed_hosts                    = list(string)
    initial_cluster_manager_nodes = optional(list(string), [])
    verify_domains                = bool

    audit = optional(object({
      enabled = optional(bool, false)
      index   = string

      external = optional(object({
        http_endpoints = optional(list(string), [])
        auth = object({
          ca_cert     = optional(string, "")
          client_cert = optional(string, "")
          client_key  = optional(string, "")
          username    = optional(string, "")
          password    = optional(string, "")
        })
      }), {
        http_endpoints = []
        auth = {
          ca_cert     = ""
          client_cert = ""
          client_key  = ""
          username    = ""
          password    = ""
        }
      })

      ignore_users    = optional(list(string), [])
      ignore_requests = optional(list(string), [])
    }), {
      index = ""
    })
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
  type        = bool
  default     = true
}
