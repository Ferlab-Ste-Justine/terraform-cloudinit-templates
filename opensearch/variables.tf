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

variable "snapshot_repository" {
  description = "S3 snapshot repository configuration"
  type = object({
    enabled           = bool
    repository_name   = string
    bucket            = string
    endpoint          = string
    region            = string
    base_path         = optional(string, "")
    protocol          = optional(string, "https")
    path_style_access = optional(bool, true)
    access_key        = optional(string, "")
    secret_key        = optional(string, "")
    ca_cert           = optional(string, "")
    timer_on_boot_sec = optional(number, 900)
    timer_interval_sec = optional(number, 14400)
  })
  default = {
    enabled           = false
    repository_name   = "opensearch-snapshots"
    bucket            = ""
    endpoint          = ""
    region            = ""
    base_path         = ""
    protocol          = "https"
    path_style_access = true
    access_key        = ""
    secret_key        = ""
    ca_cert           = ""
    timer_on_boot_sec = 900
    timer_interval_sec = 14400
  }

  validation {
    condition = !(
      var.snapshot_repository.enabled &&
      (
        var.snapshot_repository.bucket == "" ||
        var.snapshot_repository.endpoint == "" ||
        var.snapshot_repository.region == ""
      )
    )
    error_message = "When snapshot_repository is enabled, bucket, endpoint, and region must be provided."
  }
}

variable "snapshot_restore" {
  description = "Optional snapshot restore configuration"
  type = object({
    enabled              = bool
    repository_name      = string
    snapshot_name        = string
    wait_for_completion  = optional(bool, true)
    include_global_state = optional(bool, true)
    indices              = optional(list(string), [])
    rename_pattern       = optional(string, "")
    rename_replacement   = optional(string, "")
  })
  default = {
    enabled              = false
    repository_name      = ""
    snapshot_name        = ""
    wait_for_completion  = true
    include_global_state = true
    indices              = []
    rename_pattern       = ""
    rename_replacement   = ""
  }

  validation {
    condition = !(
      var.snapshot_restore.enabled &&
      (
        var.snapshot_restore.repository_name == "" ||
        var.snapshot_restore.snapshot_name == ""
      )
    )
    error_message = "When snapshot_restore is enabled, repository_name and snapshot_name must be provided."
  }
}
