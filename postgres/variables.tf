variable "install_dependencies" {
  description = "Whether to install/download application dependencies. "
  type        = bool
}

variable "advertise_ip" {
  description = "Ip the virtual machine can be reached on by others."
  type        = string
}

variable "etcd" {
  description = "Parameters for patroni's etcd store"
  type        = object({
    ca_cert   = string
    username  = string
    password  = string
    endpoints = list(string)
  })
}

variable "postgres" {
  description = "Parameters pertaining to postgres"
  type        = object({
    replicator_password = string
    superuser_password  = string
    ca_cert             = string
    server_cert         = string
    server_key          = string
    params              = list(object({
      key   = string
      value = string
    }))
  })
}

variable "patroni" {
  description = "Parameters pertaining to patroni"
  type        = object({
    scope                  = string
    namespace              = string
    name                   = string
    ttl                    = number
    loop_wait              = number
    retry_timeout          = number
    master_start_timeout   = number
    master_stop_timeout    = number
    watchdog_safety_margin = number
    use_pg_rewind          = bool
    is_synchronous         = bool
    synchronous_settings   = object({
      strict = bool
      synchronous_node_count = number
    })
    asynchronous_settings  = object({
      maximum_lag_on_failover = number
    })
    api                    = object({
      ca_cert       = string
      server_cert   = string
      server_key    = string
      client_cert   = string
      client_key    = string
    })
  })
}

variable "patroni_version" {
  description = "Version of patroni to use install"
  type        = string
  default     = ""
}