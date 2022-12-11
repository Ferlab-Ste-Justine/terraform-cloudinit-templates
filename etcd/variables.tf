variable "install_dependencies" {
  description = "Whether to install/download application dependencies. "
  type        = bool
}

variable "etcd_host" {
  description = "Etcd host parameters"
  type        = object({
    name                     = string
    ip                       = string
    bootstrap_authentication = bool
  })
}

variable "etcd_cluster" {
  description = "Etcd parameters"
  type        = object({
    auto_compaction_mode       = string,
    auto_compaction_retention  = string,
    space_quota                = number,
    grpc_gateway_enabled       = bool,
    client_cert_auth           = bool,
    root_password              = string,
  })
}

variable "etcd_initial_cluster" {
  description = "Etcd cluster parameters"
  type        = object({
    is_initializing = bool,
    token           = string,
    members         = list(object({
      ip   = string,
      name = string,
    })),
  })
}

variable "tls" {
  description = "Tls parameters"
  type = object({
    server_cert = string
    server_key  = string
    ca_cert     = string
  })
}