variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type        = bool
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

variable "fe_leader_fqdn" {
  description = "Starrocks domain name of the fe leader node"
  type        = string
}

variable "fe_follower_fqdns" {
  description = "Starrocks domain names of every fe follower node"
  type        = list(string)
}

variable "be_fqdns" {
  description = "Starrocks domain names of every be node"
  type        = list(string)
}

variable "root_password" {
  description = "Starrocks root password"
  type        = string
  sensitive   = true
}
