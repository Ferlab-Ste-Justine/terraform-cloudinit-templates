#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
%{ for mount in mounts ~}
  - path: /etc/s3fs/${mount.bucket_name}_passwd
    owner: root:root
    permissions: "0400"
    content: |
      ${mount.access_key}:${mount.secret_key}
%{ if mount.non_amazon_s3.ca_cert != "" ~}
  - path: /etc/s3fs/${mount.bucket_name}_ca.crt
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, mount.non_amazon_s3.ca_cert)}
%{ endif ~}
%{ endfor ~}

%{ if install_dependencies ~}
packages:
  - s3fs
%{ endif ~}

runcmd:
%{ for mount in mounts ~}
%{ if mount.non_amazon_s3.url != "" ~}
  - S3COMPATIBLE_ARGS=,url=${mount.non_amazon_s3.url},use_path_request_style
%{ endif ~}
%{ if mount.non_amazon_s3.ca_cert != "" ~}
  - cp /etc/s3fs/${mount.bucket_name}_ca.crt /usr/local/share/ca-certificates
  - update-ca-certificates
%{ endif ~}
  - mkdir -p /mnt/${mount.bucket_name}
  - USER_ID=$(id -u ${mount.folder.owner})
  - GROUP_ID=$(id -g ${mount.folder.owner})
  - echo "${mount.bucket_name} /mnt/${mount.bucket_name} fuse.s3fs _netdev,allow_other,uid=$${USER_ID},gid=$${GROUP_ID},umask=${mount.folder.umask},passwd_file=/etc/s3fs/${mount.bucket_name}_passwd$${S3COMPATIBLE_ARGS} 0 0" >> /etc/fstab
%{ endfor ~}
  - mount -a
