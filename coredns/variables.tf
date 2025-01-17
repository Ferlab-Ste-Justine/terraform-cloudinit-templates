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
    cache_settings = object({
      domains  = list(string)
      max_ttl  = number  
      prefetch = object({ 
        amount   = number    
        duration = string 
      })
    })
  })
  default = {
    dns_bind_addresses = ["0.0.0.0"]
    observability_bind_address = "0.0.0.0"
    nsid = "coredns"
    zonefiles_reload_interval = "3s"
    load_balance_records = true
    alternate_dns_servers = []
    forwards = []
    cache_settings = {
      domains  = []         
      max_ttl  = 86400    
      prefetch = {                    
        amount   = 0                 
        duration = ""    
      }
    }
  }
}