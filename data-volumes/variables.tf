variable "volumes" {
  description = "Volumes to install."
  type        = list(object({
    label         = string
    device        = string
    filesystem    = string
    mount_path    = string
    mount_options = string
  }))
}