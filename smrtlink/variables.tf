variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type        = bool
}

variable "domain_name" {
  description = "Fully qualified domain name of the server"
  type        = string
}

variable "tls_custom" {
  description = "Tls custom configuration to replace the default self-signed one"
  type = object({
    cert = string
    key  = string
  })
}

variable "user" {
  description = "Smrt-link install user"
  type = object({
    name                = string
    ssh_authorized_keys = list(string)
  })
}

variable "sequencing_system" {
  description = "Sequencing system to use for the smrt-link installation"
  type        = string
}

variable "revio" {
  description = "Revio sequencing system settings"
  type        = object({
    srs_transfer = object({
      name        = string
      description = string
      host        = string
      dest_path   = string
      username    = string
      ssh_key     = string
    })
    instrument = object({
      name       = string
      ip_address = string
      secret_key = string
    })
  })
  sensitive = true
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

variable "keycloak_user_passwords" {
  description = "Keycloak user passwords to change from defaults"
  type        = object({
    admin     = string
    pbicsuser = string
  })
  sensitive = true
}

variable "smtp" {
  description = "Smtp configuration for email notifications of analysis jobs"
  type        = object({
    host     = string
    port     = number
    user     = string
    password = string
  })
  sensitive = true
}
