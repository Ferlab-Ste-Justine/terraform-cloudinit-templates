locals {
  fb_service_conf = templatefile(
    "${path.module}/fluent-bit-service.conf.tpl", 
    {
      fluentbit      = var.fluentbit
    }
  )
  fb_inputs_conf = templatefile(
    "${path.module}/fluent-bit-inputs.conf.tpl", 
    {
      fluentbit      = var.fluentbit
    }
  )
  fb_default_variables_conf = templatefile(
    "${path.module}/fluent-bit-default-variables.conf.tpl", 
    {
      fluentbit      = var.fluentbit
    }
  )
  fb_output_all_conf = templatefile(
    "${path.module}/fluent-bit-output-all.conf.tpl", 
    {
      fluentbit      = var.fluentbit
    }
  )
  fb_output_default_sources_conf = templatefile(
    "${path.module}/fluent-bit-output-default-sources.conf.tpl", 
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
      install_dependencies           = var.install_dependencies
      dynamic_config                 = var.dynamic_config
      fluentbit                      = var.fluentbit
      fb_service_conf                = local.fb_service_conf
      fb_inputs_conf                 = local.fb_inputs_conf
      fb_default_variables_conf      = local.fb_default_variables_conf
      fb_output_all_conf             = local.fb_output_all_conf
      fb_output_default_sources_conf = local.fb_output_default_sources_conf
      vault_agent_integration        = var.vault_agent_integration
    }
  )
}