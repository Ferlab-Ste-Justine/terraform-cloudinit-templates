variable "minio_server" {
  description = "Minio parameters"
  type = object({
    api_port     = number
    console_port = number
    volumes_root = string
    tls          = object({
      server_cert = string
      server_key  = string
      ca_cert     = string
    })
    auth         = object({
      root_username = string
      root_password = string
    })
    load_balancer_url = string
  })
}

variable "volume_pools" {
  description = "Minio volume pools"
  type = list(object({
    domain_template     = string
    servers_count_begin = number
    servers_count_end   = number
    mount_path_template = string
    mounts_count        = number
  }))
}

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type = bool
  default = true
}