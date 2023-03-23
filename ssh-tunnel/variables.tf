variable "ssh_host_key_rsa" {
  description = "Predefined rsa ssh host key"
  type = object({
    public = string
    private = string
  })
  default = {
    public = ""
    private = ""
  }
}

variable "ssh_host_key_ecdsa" {
  description = "Predefined ecdsa ssh host key"
  type = object({
    public = string
    private = string
  })
  default = {
    public = ""
    private = ""
  }
}

variable "tunnel" {
  description = "Setting for tunnel parameters"
  type = object({
    ssh = object({
      user = string
      authorized_key = string
    })
    accesses = list(object({
      host = string
      port = string
    }))
  })
}