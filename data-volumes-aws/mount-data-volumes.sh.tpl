#!/usr/bin/env bash
# Resolve, format-if-empty and mount EBS data volumes on AWS Nitro instances.
# Volumes are matched by their NVMe serial (the EBS volume id without dashes): the
# /dev/sd* attachment names are not present on Nitro. Idempotent and safe to re-run;
# a volume that already carries a filesystem is never reformatted unless overwrite is
# set, so its data survives an instance reprovisioning.
set -euo pipefail

%{ for volume in volumes ~}
# ---- ${volume.label} (${volume.volume_id}) ----
serial="${replace(volume.volume_id, "-", "")}"
dev=""
for _ in $(seq 1 30); do
  udevadm settle || true
  dev=$(lsblk -dno NAME,SERIAL | awk -v s="$serial" '$2 == s { print "/dev/" $1; exit }')
  [ -n "$dev" ] && break
  sleep 2
done
if [ -z "$dev" ]; then
  echo "ERROR: EBS volume ${volume.volume_id} (serial $serial) not found for ${volume.label}" >&2
  exit 1
fi
echo "${volume.label} resolved to $dev"
if [ "${volume.overwrite}" = "true" ] || ! blkid "$dev" >/dev/null 2>&1; then
  echo "formatting $dev as ${volume.filesystem} (label ${volume.label})"
  mkfs.${volume.filesystem} ${volume.filesystem == "xfs" ? "-f" : "-F"} -L "${volume.label}" "$dev"
else
  echo "$dev already has a filesystem, keeping it"
fi
uuid=$(blkid -s UUID -o value "$dev")
mkdir -p "${volume.mount_path}"
grep -q "UUID=$uuid " /etc/fstab || echo "UUID=$uuid ${volume.mount_path} ${volume.filesystem} ${volume.mount_options} 0 2" >> /etc/fstab
mountpoint -q "${volume.mount_path}" || mount "${volume.mount_path}"
echo "${volume.label} mounted at ${volume.mount_path}"
%{ endfor ~}
