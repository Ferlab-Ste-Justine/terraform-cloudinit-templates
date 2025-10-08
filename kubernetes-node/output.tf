output "configuration" {
  description = "Cloud-init configuration fragment for Kubernetes node basics"
  value = templatefile("${path.module}/user_data.yaml.tpl", {
    docker_registry_auth = var.docker_registry_auth
    audit                = var.audit
  })
}