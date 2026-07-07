variable "dependencies" {
  description = "Dependency installation and StarRocks artifact source"
  type = object({
    install = optional(bool, true)
    packages = optional(object({
      common   = optional(list(string), ["openjdk-17-jdk", "sysfsutils"])
      frontend = optional(list(string), ["mysql-client"])
    }), {})
    java_home         = optional(string, "/usr/lib/jvm/java-17-openjdk-amd64")
    starrocks_tar_url = optional(string, "https://releases.starrocks.io/starrocks/StarRocks-3.5.19-ubuntu-amd64.tar.gz")
  })
  default = {}
}

variable "timezone" {
  description = "Timezone"
  type        = string
}

variable "hosts_file_patch" {
  description = "Patch to add FQDN for the node IP in /etc/hosts"
  type = object({
    enabled = bool
    fqdn    = string
  })
}

variable "node_type" {
  description = "Starrocks node type to configure: fe, be (shared-nothing) or cn (shared-data compute node)"
  type        = string

  validation {
    condition     = contains(["fe", "be", "cn"], var.node_type)
    error_message = "node_type must be one of fe, be, cn."
  }
}

variable "fe_config" {
  description = "Starrocks fe configuration"
  type = object({
    initial_leader = object({
      enabled           = bool
      fe_follower_fqdns = list(string)
      be_fqdns          = list(string)
      cn_fqdns          = optional(list(string), [])
      root_password = object({
        literal      = optional(string)
        shell_source = optional(string)
      })
      users = list(object({
        name         = string
        password     = string
        default_role = string
      }))
    })
    initial_follower = object({
      enabled        = bool
      fe_leader_fqdn = string
    })
    ssl = object({
      enabled                = bool
      cert                   = string
      key                    = string
      keystore_password      = string
      force_secure_transport = optional(bool, false)
    })
    iceberg_rest = object({
      ca_cert  = string
      env_name = string
    })
    meta_dir = string
    shared_data = optional(object({
      enabled              = optional(bool, false)
      storage_type         = optional(string, "S3")
      s3_endpoint          = optional(string, "")
      s3_path              = optional(string, "")
      s3_region            = optional(string, "")
      use_instance_profile = optional(bool, false)
      access_key           = optional(string, "")
      secret_key           = optional(string, "")
    }), {})
    additional_conf = optional(list(string), [])
  })
  sensitive = true
}

variable "be_storage_root_path" {
  description = "Starrocks be storage root path"
  type        = string
}

variable "cn_config" {
  description = "Starrocks cn (shared-data compute node) configuration"
  type = object({
    storage_root_path   = optional(string, "/opt/starrocks/storage")
    priority_networks   = optional(string, "")
    mem_limit           = optional(string, "80%")
    datacache_mem_size  = optional(string, "40%")
    datacache_disk_size = optional(string, "80%")
  })
  default = {}
}

