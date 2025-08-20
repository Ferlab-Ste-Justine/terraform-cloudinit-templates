variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type        = bool
}

variable "mounts" {
  description = "List of s3 mounts with their configurations"
  sensitive   = true
  type        = list(object({
    bucket_name   = string
    access_key    = string
    secret_key    = string
    non_amazon_s3 = object({
      url     = string
      ca_cert = string
    })
    folder = object({
      owner = string
      umask = string
    })
  }))
}
