output "configuration" {
  description = "Cloudinit compatible chrony configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      chrony               = var.chrony
    }
  )
}