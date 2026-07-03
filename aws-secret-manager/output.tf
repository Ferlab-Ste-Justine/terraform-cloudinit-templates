output "configuration" {
  description = "Cloudinit compatible aws secrets manager integrations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      region = var.region
      shell_sources = var.shell_sources
    }
  )
}