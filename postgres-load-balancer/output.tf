locals {
  haproxy_config = templatefile(
    "${path.module}/lb-haproxy.cfg.tpl",
    {
      haproxy = var.haproxy
    }
  )
  container_params = {
    fluentd = var.fluentd.tag != "" ? "--log-driver=fluentd --log-opt fluentd-address=127.0.0.1:${var.fluentd.port} --log-opt fluentd-async-connect=true --log-opt fluentd-retry-wait=1s --log-opt fluentd-max-retries=3600 --log-opt fluentd-sub-second-precision=true --log-opt tag=${var.fluentd.tag}" : ""
    config = var.container_registry.url != "" ? "--config /opt/docker" : ""
  }
}

output "configuration" {
  description = "Cloudinit compatible opensearch configurations"
  sensitive = true
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      haproxy_config = local.haproxy_config
      container_params = local.container_params
      container_registry = var.container_registry
      patroni_api = var.haproxy.patroni_api
    }
  )
}