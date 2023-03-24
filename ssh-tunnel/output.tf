output "configuration" {
  description = "Cloudinit compatible ssh tunnel configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      tunnel = var.tunnel
      ssh_host_key_rsa = var.ssh_host_key_rsa
      ssh_host_key_ecdsa = var.ssh_host_key_ecdsa
    }
  )
}