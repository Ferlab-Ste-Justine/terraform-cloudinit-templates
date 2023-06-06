output "configuration" {
  description = "Cloudinit compatible pxe configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      dhcp                 = var.dhcp
      pxe                  = var.pxe
      install_dependencies = var.install_dependencies
    }
  )
}