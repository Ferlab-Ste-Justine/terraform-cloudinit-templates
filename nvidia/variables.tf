variable "install_dependencies" {
  description = "Whether to install NVIDIA packages and CUDA toolkit."
  type        = bool
}

variable "driver_branch" {
  description = "NVIDIA driver branch number (e.g. 535, 570, 595)."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{3}$", var.driver_branch))
    error_message = "driver_branch must be a 3-digit number (e.g. 535, 570, 595)."
  }
}

variable "cuda_version" {
  description = "CUDA toolkit version in APT format (e.g. 12-6, 13-1). When empty, only the driver is installed."
  type        = string
  default     = ""

  validation {
    condition     = var.cuda_version == "" || can(regex("^[0-9]+-[0-9]+$", var.cuda_version))
    error_message = "cuda_version must be empty or in APT format (e.g. 12-6, 13-1)."
  }
}

variable "use_open_kernel_module" {
  description = "Use nvidia-open-<branch> (open kernel module, recommended for Turing+/Hopper). Default uses cuda-drivers-<branch> (proprietary)."
  type        = bool
  default     = false
}

variable "install_fabricmanager" {
  description = "Install nvidia-fabricmanager-<branch> and enable the service. Only for NVSwitch-based multi-GPU topologies (DGX/HGX). Do NOT use on direct NVLink setups."
  type        = bool
  default     = false
}
