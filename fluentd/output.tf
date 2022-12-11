locals {
  fluentd_conf = templatefile(
    "${path.module}/fluentd.conf.tpl", 
    {
      fluentd             = var.fluentd
      fluentd_buffer_conf = var.fluentd.buffer.customized ? var.fluentd.buffer.custom_value : file("${path.module}/fluentd_buffer.conf")
    }
  )
}

output "configuration" {
  description = "Cloudinit compatible fluentd configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      fluentd              = var.fluentd
      fluentd_conf         = local.fluentd_conf
    }
  )
}