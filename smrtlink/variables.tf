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
    cert                    = string
    key                     = string
    vault_agent_secret_path = string
  })
}

variable "user" {
  description = "Smrt-link install user"
  type        = string
}

variable "revio" {
  description = "Revio sequencing system settings"
  type        = object({
    srs_transfer = object({
      name          = string
      description   = string
      host          = string
      dest_path     = string
      relative_path = string
      username      = string
      ssh_key       = string
    })
    s3compatible_transfer = object({
        name        = string
        description = string
        endpoint    = string
        bucket      = string
        region      = string
        path        = string
        access_key  = string
        secret_key  = string
    })
    instrument = object({
      name          = string
      ip_address    = string
      secret_key    = string
      transfer_name = string
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
  description = "Keycloak user passwords of built-in users to change from defaults"
  type        = object({
    admin     = string
    pbicsuser = string
  })
  sensitive = true
}

variable "keycloak_users" {
  description = "Keycloak users to create"
  type        = list(object({
    id         = string
    password   = string
    role       = string
    first_name = string
    last_name  = string
    email      = string
  }))
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

variable "db_backups" {
  description = "Database backups configuration"
  type        = object({
    enabled         = bool
    cron_expression = string
    retention_days  = number
  })
}

variable "restore_db" {
  description = "Whether to restore the latest smrtlinkdb database backup when the vm is created"
  type        = bool
}
