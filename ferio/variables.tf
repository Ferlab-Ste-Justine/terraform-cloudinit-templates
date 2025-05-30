variable "ferio" {
  description = "Ferio configurations"
  type = object({
    etcd         = object({
      config_prefix      = string
      workspace_prefix   = string
      endpoints          = list(string)
      connection_timeout = string
      request_timeout    = string
      retry_interval     = string
      retries            = number
      auth               = object({
        ca_cert       = string
        client_cert   = string
        client_key    = string
        username      = string
        password      = string
      })
    })
    host         = string
    log_level    = string
  })
  default = {
    etcd = {
      config_prefix      = ""
      workspace_prefix   = ""
      endpoints          = []
      connection_timeout = ""
      request_timeout    = ""
      retry_interval     = ""
      retries            = 0
      auth               = {
        ca_cert     = ""
        client_cert = ""
        client_key  = ""
        username    = ""
        password    = ""
      }
    }
    binaries_dir = ""
    host         = ""
    log_level    = ""
  }
}

variable "minio_os_uid" {
  description = "Uid that the minio os user will run as. Minio user will not be created if negative"
  type        = number
}

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type = bool
  default = true
}