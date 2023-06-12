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
    fs_base_path = string
    calendar     = string
    bucket       = string
    paths        = list(string)
    symlinks     = string
  })
  default = {
    fs_base_path = ""
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
    fs_base_path = string
    sync_once    = bool
    calendar     = string
    bucket       = string
    paths        = list(string)
    symlinks     = string
  })
  default = {
    fs_base_path = ""
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

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type = bool
  default = true
}