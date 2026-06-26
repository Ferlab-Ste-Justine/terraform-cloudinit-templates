variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type        = bool
}

variable "timezone" {
  description = "Timezone"
  type        = string
}

variable "hosts_file_patch" {
  description = "Patch to add FQDN for the node IP in /etc/hosts"
  type        = object({
    enabled = bool
    fqdn    = string
  })
}

variable "release_version" {
  description = "Starrocks release version to install"
  type        = string
}

variable "node_type" {
  description = "Starrocks node type to configure, either fe or be"
  type        = string
}

variable "fe_config" {
  description = "Starrocks fe configuration"
  type        = object({
    initial_leader = object({
      enabled           = bool
      fe_follower_fqdns = list(string)
      be_fqdns          = list(string)
      root_password     = string
      users             = list(object({
        name         = string
        password     = string
        default_role = string
      }))
    })
    initial_follower = object({
      enabled        = bool
      fe_leader_fqdn = string
    })
    ssl = object({
      enabled           = bool
      cert              = string
      key               = string
      keystore_password = string
    })
    iceberg_rest = object({
      ca_cert  = string
      env_name = string
    })
    meta_dir = string
  })
  sensitive = true
}

variable "be_storage_root_path" {
  description = "Starrocks be storage root path"
  type        = string
}

variable "download_base_url" {
  description = "Base URL the node downloads the StarRocks tarball from (<download_base_url>/StarRocks-<release_version>-ubuntu-amd64.tar.gz). An https:// URL is fetched with wget; an s3:// URL is fetched with 'aws s3 cp' (requires the AWS CLI and credentials on the node), which lets nodes pull from a private S3 bucket without an HTTP proxy. Defaults to the public StarRocks releases server."
  type        = string
  default     = "https://releases.starrocks.io/starrocks"
}
