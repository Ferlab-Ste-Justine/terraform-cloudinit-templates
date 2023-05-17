locals {
  fluentbit_conf = templatefile(
    "${path.module}/fluent-bit.conf.tpl", 
    {
      fluentbit      = var.fluentbit
      is_go_template = false
    }
  )
  fluentbit_conf_template = templatefile(
    "${path.module}/fluent-bit.conf.tpl", 
    {
      fluentbit      = var.fluentbit
      is_go_template = true
    }
  )
}

output "configuration" {
  description = "Cloudinit compatible fluentd configurations"
  sensitive = true
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies    = var.install_dependencies
      fluentbit               = var.fluentbit
      fluentbit_conf          = local.fluentbit_conf
      fluentbit_conf_template = local.fluentbit_conf_template
    }
  )
}