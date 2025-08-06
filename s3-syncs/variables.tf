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
    calendar     = string
    bucket       = string
    paths        = list(object({
      fs = string
      s3 = string
    }))
    symlinks     = string
  })
  default = {
    calendar     = ""
    bucket       = ""
    paths        = []
    symlinks     = "copy"
  }

  validation {
    condition     = contains(["copy", "follow", "skip"], var.outgoing_sync.symlinks)
    error_message = "value for symlinks argument must be one of: \"copy\", \"follow\" or \"ignore\"."
  }
}

variable "incoming_sync" {
  description = "Object store parameters"
  type = object({
    sync_once    = bool
    calendar     = string
    bucket       = string
    paths        = list(object({
      fs = string
      s3 = string
    }))
    symlinks     = string
  })
  default = {
    sync_once    = false
    calendar     = ""
    bucket       = ""
    paths        = []
    symlinks     = "copy"
  }

  validation {
    condition     = contains(["copy", "follow", "skip"], var.incoming_sync.symlinks)
    error_message = "value for symlinks argument must be one of: \"copy\", \"follow\" or \"ignore\"."
  }
}

variable "user" {
  description = "User to run the services as"
  type        = string
  default     = "root"
}

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type = bool
  default = true
}