output "configuration" {
  description = "Cloudinit config that formats (if empty) and mounts EBS data volumes, resolved by NVMe serial."
  value = templatefile(
    "${path.module}/user_data.yaml.tpl",
    {
      mount_script = templatefile(
        "${path.module}/mount-data-volumes.sh.tpl",
        { volumes = var.volumes }
      )
    }
  )
}
