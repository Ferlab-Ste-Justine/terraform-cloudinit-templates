variable "object_store" {
  description = "Object store parameters"
  type = object({
    url                    = string
    region                 = string
    access_key             = string
    secret_key             = string
    server_side_encryption = string
    ca_cert                = string
  })
}

variable "outgoing_sync" {
  description = "Object store parameters"
  type = object({
    calendar   = string
    bucket     = string
    paths      = list(string)
  })
  default = {
    calendar   = ""
    bucket     = ""
    paths      = []
  }
}

variable "incoming_sync" {
  description = "Object store parameters"
  type = object({
    sync_once  = bool
    calendar   = string
    bucket     = string
    paths      = list(string)
  })
  default = {
    sync_once  = false
    calendar   = ""
    bucket     = ""
    paths      = []
  }
}

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type = bool
  default = true
}