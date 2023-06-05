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

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type = bool
  default = true
}