variable "install_dependencies" {
  description = "Whether to install/download application dependencies. "
  type        = bool
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