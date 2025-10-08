variable "docker_registry_auth" {
  description = "Docker registry authentication settings"
  type = object({
    enabled  = bool
    url      = string
    username = string
    password = string
  })
}

variable "audit" {
  type = object({
    enabled          = bool
    policy_file_path = optional(string, "/etc/kubernetes/audit-policy/apiserver-audit-policy.yaml")
    rules = optional(list(object({
      level = string
      verbs = optional(list(string), [])
    })), [
      { level = "Metadata" },
      { level = "RequestResponse", verbs = ["create","update","patch","delete","deletecollection"] }
    ])
  })
}

variable "install_dependencies" {
  description = "For consistency with other submodules"
  type        = bool
  default     = true
}