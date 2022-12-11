variable "install_dependencies" {
  description = "Whether to install/download application dependencies. "
  type        = bool
}

variable "chrony" {
  description = "Chrony configuration for ntp."
  type        = object({
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#server
    servers = list(object({
      url = string,
      options = list(string)
    })),
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#pool
    pools = list(object({
      url = string,
      options = list(string)
    })),
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#makestep
    makestep = object({
      threshold = number
      limit = number
    })
  })
}