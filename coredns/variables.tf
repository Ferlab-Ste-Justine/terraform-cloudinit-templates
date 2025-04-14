variable "install_dependencies" {
  description = "Whether to install/download application dependencies. "
  type        = bool
}

variable "dns" {
  description = "Parameters for the dns server"
  type        = object({
    dns_bind_addresses = list(string)
    observability_bind_address = string
    nsid = string
    zonefiles_reload_interval = string
    load_balance_records = bool
    alternate_dns_servers = list(string)
    forwards = list(object({
      domain_name = string,
      dns_servers = list(string)
    }))
    cache = object({
      domains  = list(string)
      max_ttl  = number  
      prefetch = object({ 
        amount   = number    
        duration = string 
      })
    })
  })
}