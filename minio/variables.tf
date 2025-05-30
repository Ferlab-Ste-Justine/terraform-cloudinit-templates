variable "minio_server" {
  description = "Minio parameters"
  type = object({
    api_port     = number
    console_port = number
    volumes_roots = list(string)
    tls          = object({
      server_cert = string
      server_key  = string
      ca_certs    = list(string)
    })
    auth         = object({
      root_username = string
      root_password = string
    })
    api_url      = string
    console_url  = string
  })
}

variable "kes" {
  description = "Optional parameters for minio to use kes"
  type = object({
    endpoint = string
    tls = object({
      client_cert = string
      client_key = string
      ca_cert = string
    })
    key = string
  })
  default = {
    endpoint = ""
    tls = {
      client_cert = ""
      client_key = ""
      ca_cert = ""
    }
    key = ""
  }
}

variable "prometheus_auth_type" {
  description = "Authentication mode for prometheus scraping endpoints"
  type        = string
  default     = ""
}

variable "godebug_settings" {
  description = "Comma-separated list of settings for environment variable GODEBUG"
  type        = string
  default     = ""
}

variable "minio_os_uid" {
  description = "Uid that the minio os user will run as. Minio user will not be created if negative"
  type        = number
}

variable "volume_pools" {
  description = "Minio volume pools, relevant if not using ferio"
  type = list(object({
    domain_template     = string
    servers_count_begin = number
    servers_count_end   = number
    mount_path_template = string
    mounts_count        = number
  }))
  default = []
}

variable "minio_download_url" {
  description = "Url to download minio from"
  type = string
  default = ""
}

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type = bool
  default = true
}

variable "setup_minio_service" {
  description = "Whether the minio binary setup and systemd service are managed from this cloud-init config. Would be false if using ferio for example."
  type = bool
  default = true
}