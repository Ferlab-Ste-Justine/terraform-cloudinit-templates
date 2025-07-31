locals { 
    incoming_sync_rclone_args = concat(
        var.object_store.ca_cert != "" ? ["--ca-cert", "/etc/s3-sync/ca.crt"] : [],
        var.incoming_sync.symlinks == "follow" ? ["--copy-links"] : [],
        var.incoming_sync.symlinks == "copy" ? ["--links"] : [],
        var.incoming_sync.symlinks == "skip" ? ["--skip-links"] : [],
    )
    outgoing_sync_rclone_args = concat(
        var.object_store.ca_cert != "" ? ["--ca-cert", "/etc/s3-sync/ca.crt"] : [],
        var.outgoing_sync.symlinks == "follow" ? ["--copy-links"] : [],
        var.outgoing_sync.symlinks == "copy" ? ["--links"] : [],
        var.outgoing_sync.symlinks == "skip" ? ["--skip-links"] : [],
    )
}


output "configuration" {
  description = "Cloudinit compatible S3 backup configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      object_store = var.object_store
      outgoing_sync = var.outgoing_sync
      incoming_sync = var.incoming_sync
      incoming_sync_rclone_args = join(" ", local.incoming_sync_rclone_args)
      outgoing_sync_rclone_args = join(" ", local.outgoing_sync_rclone_args)
      user = var.user
    }
  )
}