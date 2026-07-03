variable "region" {
  description = "AWS region where the secrets will be fetched"
  type        = string
}

variable "shell_sources" {
  description = "Secrets that should be put into shell sources"
  type = list(object({
    script_path = string
    secrets = list(object({
      secret_id = string
      variable_name = string
    }))
  }))
}
