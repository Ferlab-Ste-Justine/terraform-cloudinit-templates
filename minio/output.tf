locals {
  volume_pools = length(var.volume_pools) > 0 && var.setup_minio_service ? [
    for minio_server in var.minio_servers: minio_server.tenant_name != "" ? join(" ", [
        for pool in var.volume_pools: "https://${format(pool.domain_template, "{${pool.servers_count_begin}...${pool.servers_count_end}}")}:${minio_server.api_port}${format(pool.mount_path_template, "{1...${pool.mounts_count}}")}/${minio_server.tenant_name}" 
      ]) : join(" ", [
        for pool in var.volume_pools: "https://${format(pool.domain_template, "{${pool.servers_count_begin}...${pool.servers_count_end}}")}:${minio_server.api_port}${format(pool.mount_path_template, "{1...${pool.mounts_count}}")}"
      ])
  ]: []
}

output "configuration" {
  description = "Cloudinit compatible minio configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      setup_minio_service  = var.setup_minio_service
      minio_servers        = [for minio_server in var.minio_servers: 
        merge(minio_server, {
          config_path = minio_server.tenant_name == "" ? "/etc/minio" : "/etc/minio/${minio_server.tenant_name}"
          service_name = minio_server.tenant_name == "" ? "minio.service" : "minio-${minio_server.tenant_name}.service"
        })
      ]
      volume_roots         = var.volume_roots
      kes                  = var.kes
      prometheus_auth_type = var.prometheus_auth_type
      godebug_settings     = var.godebug_settings
      volume_pools         = local.volume_pools
      minio_download_url   = var.minio_download_url
      minio_os_uid         = var.minio_os_uid
    }
  )
}