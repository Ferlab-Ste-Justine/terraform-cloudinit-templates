variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type        = bool
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

variable "release_version" {
  description = "Starrocks release version to install"
  type        = string
}

variable "node_type" {
  description = "Starrocks node type to configure, either fe or be"
  type        = string
}

variable "fe_config" {
  description = "Starrocks fe configuration"
  type = object({
    initial_leader = object({
      enabled           = bool
      fe_follower_fqdns = list(string)
      be_fqdns          = list(string)
      root_password     = string
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
  })
  sensitive = true
}

variable "be_storage_root_path" {
  description = "Starrocks be storage root path"
  type        = string
}

variable "data_volume" {
  description = "Optional dedicated data volume for StarRocks data — point meta_dir / be_storage_root_path inside mount_path so it survives OS-disk reprovisioning. Optionally LUKS-encrypted, formatted ext4 only if empty, mounted via fstab/crypttab. Idempotent: an existing LUKS header or filesystem is never reformatted."
  type = object({
    enabled    = bool
    device     = string
    mount_path = string
    luks = optional(object({
      enabled    = bool
      passphrase = string
    }), { enabled = false, passphrase = "" })
  })
  default = {
    enabled    = false
    device     = ""
    mount_path = ""
  }
  sensitive = true
}
