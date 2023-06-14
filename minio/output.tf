locals {
  volume_pools = join(" ", [
    for pool in var.volume_pools: "https://${format(pool.domain_template, "{${pool.servers_count_begin}...${pool.servers_count_end}}")}:${var.minio_server.api_port}${format(pool.mount_path_template, "{1...${pool.mounts_count}}")}"
  ])
}

output "configuration" {
  description = "Cloudinit compatible minio configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      minio_server         = var.minio_server
      volume_pools        = local.volume_pools
    }
  )
}