variable "network_interfaces" {
  description = "List of network interfaces. Each entry has the following keys: interface, prefix_length, ip, mac, gateway (optional) and dns_servers (optional)."
  type        = list(object({
    interface     = string
    prefix_length = string
    ip            = string
    mac           = string
    gateway       = string
    dns_servers   = list(string)
  }))
}