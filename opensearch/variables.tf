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
  description = <<-EOT
    S3 snapshot repository configuration for OpenSearch snapshots.
    
    When enabled=true, this configures OpenSearch to store snapshots in an S3-compatible object store.
    
    Fields:
    - enabled: Whether to enable snapshot repository configuration
    - repository_name: Name for the snapshot repository in OpenSearch
    - bucket: S3 bucket name (required if enabled)
    - endpoint: S3 endpoint URL without protocol (e.g., "s3.amazonaws.com" or "minio.example.com:9000") (required if enabled)
    - region: S3 region (e.g., "us-east-1") (required if enabled)
    - base_path: Optional base path within bucket for snapshots
    - protocol: Protocol for S3 connection ("https" or "http")
    - path_style_access: Whether to use path-style S3 access (true for MinIO/most S3-compatible stores, false for AWS S3)
    - access_key: S3 access key. SECURITY NOTE: IAM roles are preferred over static credentials when possible
    - secret_key: S3 secret key. SECURITY NOTE: IAM roles are preferred over static credentials when possible
    - ca_cert: Optional CA certificate in PEM format for TLS verification of S3 endpoint
  EOT
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
  }
  
  # Validation: If snapshot repository is enabled, bucket, endpoint, and region must be non-empty
  validation {
    condition = (
      !var.snapshot_repository.enabled ||
      (
        length(trim(var.snapshot_repository.bucket)) > 0 &&
        length(trim(var.snapshot_repository.endpoint)) > 0 &&
        length(trim(var.snapshot_repository.region)) > 0
      )
    )
    error_message = "If snapshot_repository.enabled is true, then bucket, endpoint, and region must all be non-empty strings."
  }
}

variable "snapshot_restore" {
  description = <<-EOT
    Optional snapshot restore configuration for OpenSearch.
    
    When enabled=true, restores a snapshot during initial cluster bootstrap.
    
    Fields:
    - enabled: Whether to restore a snapshot on bootstrap
    - repository_name: Name of the snapshot repository to restore from (required if enabled)
    - snapshot_name: Name of the snapshot to restore (required if enabled)
    - wait_for_completion: Whether to wait for restore to complete before returning
    - include_global_state: Whether to restore global cluster state
    - indices: List of index patterns to restore (empty = all indices except security)
    - rename_pattern: Regex pattern for renaming indices during restore
    - rename_replacement: Replacement string for rename_pattern
  EOT
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
  
  # Validation: If snapshot restore is enabled, repository_name and snapshot_name must be non-empty
  validation {
    condition = (
      var.snapshot_restore.enabled == false ||
      (
        trim(var.snapshot_restore.repository_name) != "" &&
        trim(var.snapshot_restore.snapshot_name) != ""
      )
    )
    error_message = "If snapshot_restore.enabled is true, both repository_name and snapshot_name must be non-empty strings."
  }
}

variable "snapshot_timer" {
  description = <<-EOT
    Configuration for the snapshot timer schedule.
    
    Controls when and how frequently OpenSearch snapshots are taken automatically.
    
    Fields:
    - on_boot_sec: Initial delay after boot before first snapshot (systemd time format, e.g., "15min", "1h")
    - on_unit_active_sec: Interval between snapshots (systemd time format, e.g., "4h", "1d")
  EOT
  type = object({
    on_boot_sec        = optional(string, "15min")
    on_unit_active_sec = optional(string, "4h")
  })
  default = {
    on_boot_sec        = "15min"
    on_unit_active_sec = "4h"
  }
}
