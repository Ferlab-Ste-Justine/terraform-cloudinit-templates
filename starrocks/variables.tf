variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type        = bool
}

variable "timezone" {
  description = "Timezone"
  type        = string
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
    is_leader_at_start = bool
    ssl                = object({
      enabled           = bool
      keystore_base64   = string
      keystore_password = string
      key_password      = string
    })
    root_password = string
  })
}

variable "network_info" {
  description = "Starrocks network information"
  type        = object({
    fe_leader_node = object({
      ip   = string
      fqdn = string
    })
    fe_follower_nodes = list(object({
      ip   = string
      fqdn = string
    }))
    be_nodes = list(object({
      ip   = string
      fqdn = string
    }))
  })
}
