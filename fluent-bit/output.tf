locals {
  fluentbit_service_conf = templatefile(
    "${path.module}/fluent-bit-service.conf.tpl", 
    {
      fluentbit      = var.fluentbit
    }
  )
  fluentbit_inputs_conf = templatefile(
    "${path.module}/fluent-bit-inputs.conf.tpl", 
    {
      fluentbit      = var.fluentbit
    }
  )
  fluentbit_output_conf = templatefile(
    "${path.module}/fluent-bit-output.conf.tpl", 
    {
      fluentbit      = var.fluentbit
    }
  )
}

output "configuration" {
  description = "Cloudinit compatible fluentd configurations"
  sensitive = true
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies   = var.install_dependencies
      fluentbit              = var.fluentbit
      etcd                   = var.etcd
      fluentbit_service_conf = local.fluentbit_service_conf
      fluentbit_inputs_conf  = local.fluentbit_inputs_conf
      fluentbit_output_conf  = local.fluentbit_output_conf
    }
  )
}