variable "proxy" {
  description = "Parameters for proxy"
  type = object({
    server_name     = string
    max_connections = number
    idle_timeout    = string
    listening_port  = string
  })
}

/*
See:
https://ubuntu.com/server/docs/service-nfs
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/storage_administration_guide/nfs-serverconfig
*/
variable "nfs_configs" {
  description = "List of nfs configurations containing a subset of possible nfs configurations. It is a list of objects, each entry containing the following fields: path, domain, rw (true or false), sync (true or false), subtree_check (true or false), no_root_squash (true or false)"
  type        = list(object({
    path = string
    rw = bool
    sync = bool
    subtree_check = bool
    no_root_squash = bool
  }))
  default = []
}

variable "tls" {
  description = "Tls parameters"
  type = object({
    server_cert = string
    server_key  = string
    ca_cert     = string
  })
}

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type = bool
  default = true
}