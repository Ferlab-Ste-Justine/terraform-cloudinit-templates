variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type        = bool
}

variable "hostname" {
  description = "Hostname to advertise to other Vault servers in the cluster for request forwarding"
  type        = string
}

variable "release_version" {
  description = "Vault release version to install"
  type        = string
}

variable "tls" {
  description = "Configuration for a secure vault communication over tls"
  type        = object({
    ca_certificate     = string
    server_certificate = string
    server_key         = string
    client_auth        = bool
  })
}

variable "etcd_backend" {
  description = "Parameters for the etcd backend"
  type        = object({
    key_prefix     = string
    urls           = string
    ca_certificate = string
    client         = object({
      certificate = string
      key         = string
      username    = string
      password    = string
    })
  })
}