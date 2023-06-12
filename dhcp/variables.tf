variable "dhcp" {
  description = "Parameters for dhcp server"
  type = object({
    interfaces = list(string)
    networks = list(object({
      addresses   = string
      gateway     = string
      broadcast   = string
      dns_servers = list(string)
      range_start = string
      range_end   = string
    }))
  })
  default = {
    interfaces = []
    networks = []
  }
}

variable "pxe" {
  description = "Parameters for ipxe booting"
  type = object({
    enabled = bool
    self_url = string
    static_boot_script = string
    boot_script_path = string
  })
  default = {
    enabled = false
    self_url = ""
    static_boot_script = ""
    boot_script_path = "ipxe-boot-script"
  }
}

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type = bool
  default = true
}