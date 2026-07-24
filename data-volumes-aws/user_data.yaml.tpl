#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
  - path: /opt/mount-data-volumes.sh
    permissions: "0700"
    owner: root:root
    content: |
      ${indent(6, mount_script)}

runcmd:
  - /opt/mount-data-volumes.sh
