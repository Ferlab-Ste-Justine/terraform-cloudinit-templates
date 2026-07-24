variable "volumes" {
  description = "EBS data volumes to format and mount, resolved by NVMe serial (Nitro-safe)."
  type = list(object({
    label         = string
    volume_id     = string
    filesystem    = optional(string, "xfs")
    mount_path    = string
    mount_options = optional(string, "defaults,nofail,x-systemd.device-timeout=5")
    overwrite     = optional(bool, false)
  }))
}
