locals { 
  config = templatefile(
    "${path.module}/config.yml.tpl",
    {
      git                  = var.git
      filesystem           = var.filesystem
      notification_command = var.notification_command
      grpc_notifications   = var.grpc_notifications
      naming               = var.naming
      log_level            = var.log_level
    }
  )
}

output "configuration" {
  description = "Cloudinit compatible configurations-auto-updater configurations"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl", 
    {
      install_dependencies = var.install_dependencies
      naming               = var.naming
      user                 = var.user
      git                  = var.git
      filesystem           = var.filesystem
      grpc_notifications   = var.grpc_notifications
      timer_calendar       = var.timer_calendar
      config               = local.config
    }
  )
}