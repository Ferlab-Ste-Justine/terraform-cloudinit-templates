variable "filesystem" {
  description = "Parameters for the filesystem part of the synchronization"
  type        = object({
    path = string
    files_permission = string
    directories_permission = string
  })
}

variable "git" {
  description = "Parameters for git part of the synchronization"
  type        = object({
    repo = string
    ref  = string
    path = string
    auth = object({
      client_ssh_key         = string
      client_ssh_user        = string
      server_ssh_fingerprint = string
    })
    trusted_gpg_keys = list(string)
  })
}

variable "notification_command" {
  description = "Parameters of the notification command"
  type        = object({
    command = list(string)
    retries = number
  })

  default = {
    command = []
    retries = 0
  }

  validation {
    condition     = var.notification_command.retries >= 0
    error_message = "notification_command.retries argument must be greater or equal to zero."
  }
}

variable "grpc_notifications" {
  description = "Parameters to push update notification to grpc endpoints"
  type = list(object({
    endpoint = string
    filter   = string
    trim_key_path = bool
    max_chunk_size = number
    retries = number
    retry_interval = string
    request_timeout = string
    connection_timeout = string
    auth = object({
      ca_cert = string
      client_cert = string
      client_key = string
    })
  }))

  default = []
}

variable "naming" {
  description = "Customize name to give to the binary or systemd service in case you need to run several instances"
  type        = object({
    binary  = string
    service = string
  })

  default = {
    binary  = "gitsync"
    service = "gitsync"
  }

  validation {
    condition     = length(var.naming.binary) >= 0
    error_message = "naming.binary argument cannot be the empty string."
  }

  validation {
    condition     = length(var.naming.service) >= 0
    error_message = "naming.service argument cannot be the empty string."
  }
}

variable "user" {
  description = "User to run the service as"
  type = string

  default = "root"
}

variable "log_level" {
  description = "Log level"
  type = string
  
  default = "info"

  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "value for log_level argument must be one of: \"debug\", \"info\", \"warn\" or \"error\"."
  }
}

variable "timer_calendar" {
  description = "Systemd timer calendar value for the recurrence"
  type = string
  //Every minute
  default = "*-*-* *:*:00"
}

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type = bool
  
  default = true
}