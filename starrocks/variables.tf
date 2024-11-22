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

variable "is_fe_leader" {
  description = "Whether Starrocks node is the fe leader"
  type        = bool
}

variable "fe_leader_node" {
  description = "Starrocks ip and fqdn of the fe leader node"
  type        = object({
    ip   = string
    fqdn = string
  })
}

variable "fe_follower_nodes" {
  description = "Starrocks ip and fqdn of each follower node"
  type        = list(object({
    ip   = string
    fqdn = string
  }))
}

variable "be_nodes" {
  description = "Starrocks ip and fqdn of each be node"
  type        = list(object({
    ip   = string
    fqdn = string
  }))
}

variable "root_password" {
  description = "Starrocks root password"
  type        = string
  sensitive   = true
}
