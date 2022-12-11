output "configuration" {
  description = "Cloudinit compatible network configurations"
  value = templatefile(
    "${path.module}/network_config.yaml.tpl", 
    {
      network_interfaces = var.network_interfaces
    }
  )
}