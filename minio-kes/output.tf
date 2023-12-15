locals {
  kes_config = templatefile(
    "${path.module}/config.yml.tpl",
    {
      kes_server = var.kes_server
      keystore = var.keystore
    }
  )
}

output "configuration" {
  description = "Cloudinit compatible minio kes configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      kes_server           = var.kes_server
      keystore             = var.keystore
      kes_config           = local.kes_config
      install_dependencies = var.install_dependencies
    }
  )
}