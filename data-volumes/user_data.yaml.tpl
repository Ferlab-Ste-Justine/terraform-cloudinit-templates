#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

device_aliases:
%{ for volume in volumes ~}
  ${volume.label}: /dev/${volume.device}
%{ endfor ~}
disk_setup:
%{ for volume in volumes ~}
  ${volume.label}:
    table_type: gpt
    layout: True
    overwrite: False
%{ endfor ~}
fs_setup:
%{ for volume in volumes ~}
  - label: ${volume.label}
    device: ${volume.label}.1
    filesystem: ${volume.filesystem}
%{ endfor ~}
mounts:
%{ for volume in volumes ~}
  - ["${volume.label}.1", "${volume.mount_path}", "${volume.filesystem}","${volume.mount_options}", "0", "2"]
%{ endfor ~}