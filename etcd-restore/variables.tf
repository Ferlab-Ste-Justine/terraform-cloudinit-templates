variable "install_dependencies" {
  description = "Whether to install/download application dependencies. "
  type        = bool
}

variable "restore" {
  description = "Parameters to restore from an S3 backup"
  type        = object({
    s3 = object({
        endpoint      = string,
        bucket        = string,
        object_prefix = string,
        region        = string,
        access_key = string,
        secret_key = string,
        ca_cert       = string
    }),
    encryption_key  = string
    backup_timestamp = string
  })
}

variable "etcd_initial_cluster" {
  description = "Etcd cluster parameters"
  type        = object({
    name            = string,
    ip              = string,
    token           = string,
    members         = list(object({
      ip   = string,
      name = string,
    })),
  })
}