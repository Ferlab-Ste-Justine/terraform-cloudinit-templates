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
  type        = object({
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
  type        = object({
    initial_leader = object({
      enabled           = bool
      fe_follower_fqdns = list(string)
      be_fqdns          = list(string)
      root_password     = string
      users             = list(object({
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
      enabled           = bool
      cert              = string
      key               = string
      keystore_password = string
    })
    iceberg_rest = object({
      ca_cert  = string
      env_name = string
    })
    meta_dir = string
  })
  sensitive = true
}

variable "be_storage_root_path" {
  description = "Starrocks be storage root path"
  type        = string
}

variable "data_volume" {
  description = "Optional dedicated data volume for the StarRocks data directory (the FE meta_dir / BE be_storage_root_path must point inside mount_path), so the data survives reprovisioning the node's OS disk. When enabled, the device is optionally LUKS-encrypted, formatted ext4 ONLY if empty, and mounted at mount_path with fstab/crypttab for reboot persistence. The setup is idempotent: an existing LUKS header or filesystem is never reformatted (reattaching a volume keeps its data)."
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
