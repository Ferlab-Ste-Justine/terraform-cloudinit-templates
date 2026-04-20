#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies ~}
packages:
  - ca-certificates
  - cmake
  - build-essential
  - pciutils

package_update: true
package_upgrade: true
package_reboot_if_required: true
%{ endif ~}

%{ if install_dependencies ~}
runcmd:
  - wget -O /tmp/cuda-keyring.deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
  - dpkg -i /tmp/cuda-keyring.deb
  - rm /tmp/cuda-keyring.deb
  - apt-get update
%{ if use_open_kernel_module ~}
  - apt-get install -y nvidia-open-${driver_branch}
%{ else ~}
  - apt-get install -y cuda-drivers-${driver_branch}
%{ endif ~}
%{ if cuda_version != "" ~}
  - apt-get install -y cuda-toolkit-${cuda_version}
%{ endif ~}
%{ if install_fabricmanager ~}
  - apt-get install -y nvidia-fabricmanager-${driver_branch}
  - systemctl enable nvidia-fabricmanager
%{ endif ~}
%{ endif ~}

power_state:
  delay: now
  mode: reboot
  message: Rebooting after cloud-init completion
  condition: true
