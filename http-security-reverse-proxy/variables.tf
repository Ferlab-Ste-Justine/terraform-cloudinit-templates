variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type = bool
  default = true
}

variable "cpu_architecture" {
  description = "Cpu architecture, matters only if installing dependenciess is enabled. "
  type        = string
  default     = "amd64"

  validation {
    condition     = contains(["amd64", "arm64"], var.cpu_architecture)
    error_message = "cpu_architecture must be either \"amd64\" or \"arm64\"."
  }
}

variable "reverse_proxy" {
  description = "Parameters for the reverse proxy"
  type = object({
    server_name = string
    ip = string
    port = number
    max_connections = number
    user = object({
      create = bool
      name   = string
    })
    tls = optional(object({
      server_cert = string
      server_key = string
      ca_cert    = optional(string)
    }))
    backends = list(object({
      ip = optional(string, "127.0.0.1")
      port = number
      path_mappings = list(object({
        backend_path = optional(string)
        frontend_path = string
      }))
    }))
  })
}