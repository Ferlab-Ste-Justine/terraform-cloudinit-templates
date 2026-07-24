# data-volumes-aws

Cloud-init module that formats (if empty) and mounts EBS data volumes on AWS Nitro
instances. Unlike the generic `data-volumes` module — which drives cloud-init's native
`disk_setup`/`fs_setup` against a `/dev/sdX` path — this one resolves each volume by its
**NVMe serial** (the EBS volume id without dashes), because Nitro does not expose the
`/dev/sd*` attachment names.

The mount is idempotent and preservation-safe: a volume that already carries a filesystem
is never reformatted (unless `overwrite = true`), so its data survives an instance
reprovisioning. Volumes are mounted by UUID through `/etc/fstab` (`nofail` by default, so a
missing volume never blocks boot).

Use the generic `data-volumes` module for libvirt/baremetal (stable virtio `/dev/vdb`).

## Usage

```hcl
module "meta_volume" {
  source = "git::https://github.com/Ferlab-Ste-Justine/terraform-cloudinit-templates.git//data-volumes-aws?ref=vX.Y.Z"

  volumes = [{
    label      = "sr-meta"
    volume_id  = aws_ebs_volume.fe_meta.id
    mount_path = "/opt/starrocks/meta"
  }]
}
```

Then add `module.meta_volume.configuration` as a part of your `cloudinit_config`.

## Inputs

`volumes` — list of objects:

| field | required | default | description |
|-------|----------|---------|-------------|
| `label` | yes | | filesystem label and log identifier |
| `volume_id` | yes | | EBS volume id (`vol-...`), resolved by NVMe serial |
| `filesystem` | no | `xfs` | filesystem to create |
| `mount_path` | yes | | mount point |
| `mount_options` | no | `defaults,nofail,x-systemd.device-timeout=5` | fstab options |
| `overwrite` | no | `false` | reformat even when a filesystem is already present |
