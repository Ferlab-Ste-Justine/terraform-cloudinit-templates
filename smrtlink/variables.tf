variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type        = bool
}

variable "domain_name" {
  description = "Fully qualified domain name of the server"
  type        = string
}

variable "user" {
  description = "Smrt-link install user"
  type        = string
}

variable "sequencing_system" {
  description = "Sequencing system to use"
  type        = string
}

variable "release_version" {
  description = "Smrt-link release version to install"
  type        = string
}

variable "install_lite" {
  description = "Whether to install smrt-link lite edition"
  type        = bool
}

variable "workers_count" {
  description = "Maximum number of simultaneous analysis jobs"
  type        = number
}

variable "smtp" {
  description = "Smtp configuration for email notifications of analysis jobs"
  sensitive   = true
  type = object({
    host     = string
    port     = number
    user     = string
    password = string
  })
}
