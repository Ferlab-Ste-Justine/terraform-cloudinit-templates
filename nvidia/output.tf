output "configuration" {
  description = "Cloudinit compatible NVIDIA driver and CUDA toolkit configuration"
  value = templatefile(
    "${path.module}/user_data.yaml.tpl",
    {
      install_dependencies   = var.install_dependencies
      driver_branch          = var.driver_branch
      cuda_version           = var.cuda_version
      use_open_kernel_module = var.use_open_kernel_module
      install_fabricmanager  = var.install_fabricmanager
    }
  )
}
