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
    initial_leader = object({
      enabled       = bool
      root_password = string
      fe_follower_nodes = list(object({
        ip   = string
        fqdn = string
      }))
      be_nodes = list(object({
        ip   = string
        fqdn = string
      }))
    })
    initial_follower = object({
      enabled       = bool
      fe_leader_node = object({
        ip   = string
        fqdn = string
      })
    })
    ssl = object({
      enabled           = bool
      cert              = string
      key               = string
      keystore_password = string
      key_password      = string
    })
  })
}
