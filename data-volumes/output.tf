output "configuration" {
  description = "Cloudinit compatible fluentd configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      volumes = var.volumes
    }
  )
}