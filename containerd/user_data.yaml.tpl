#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
  - path: /etc/systemd/system/containerd.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description=Containerd Service
      After=network.target dbus.service

      [Service]
      Type=notify
      Delegate=yes
      KillMode=process

      Restart=always
      RestartSec=2
      StartLimitBurst=5
      StartLimitInterval=60s

      OOMScoreAdjust=-999
      LimitNPROC=infinity
      LimitCORE=infinity
      TasksMax=infinity

      ExecStartPre=-/sbin/modprobe overlay
      ExecStart=/usr/local/bin/containerd

      [Install]
      WantedBy=multi-user.target
%{ if buildkit_enabled ~}
  - path: /etc/systemd/system/buildkit.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description=BuildKit Service
      Requires=containerd.service
      After=containerd.service

      [Service]
      Type=notify
      Delegate=yes

      Restart=always
      RestartSec=2
      StartLimitBurst=5
      StartLimitInterval=60s

      LimitNOFILE=infinity
      LimitNPROC=infinity
      LimitCORE=infinity
      TasksMax=infinity

      ExecStart=/usr/local/bin/buildkitd \
        --addr unix:///run/buildkit/buildkitd.sock \
        --oci-worker=false \
        --containerd-worker=true

      [Install]
      WantedBy=multi-user.target
%{ endif ~}

runcmd:
%{ if install_dependencies ~}
#Containerd
- wget https://github.com/containerd/containerd/releases/download/v2.3.4/containerd-2.3.4-linux-${cpu_architecture}.tar.gz -O /tmp/containerd-2.3.4-linux-${cpu_architecture}.tar.gz
- tar Cxzvf /usr/local /tmp/containerd-2.3.4-linux-${cpu_architecture}.tar.gz
- rm /tmp/containerd-2.3.4-linux-${cpu_architecture}.tar.gz
#Runc
- wget https://github.com/opencontainers/runc/releases/download/v1.5.1/runc.${cpu_architecture} -O /tmp/runc.${cpu_architecture}
- install -m 755 /tmp/runc.${cpu_architecture} /usr/local/sbin/runc
- rm /tmp/runc.${cpu_architecture}
#Cni
- mkdir -p /opt/cni/bin
- wget https://github.com/containernetworking/plugins/releases/download/v1.9.1/cni-plugins-linux-${cpu_architecture}-v1.9.1.tgz -O /tmp/cni-plugins-linux-${cpu_architecture}-v1.9.1.tgz
- tar Cxzvf /opt/cni/bin /tmp/cni-plugins-linux-${cpu_architecture}-v1.9.1.tgz
- rm /tmp/cni-plugins-linux-${cpu_architecture}-v1.9.1.tgz
#Nerdctl
- wget https://github.com/containerd/nerdctl/releases/download/v2.3.5/nerdctl-2.3.5-linux-${cpu_architecture}.tar.gz -O /tmp/nerdctl-2.3.5-linux-${cpu_architecture}.tar.gz
- tar Cxzvf /usr/local/bin /tmp/nerdctl-2.3.5-linux-${cpu_architecture}.tar.gz
- rm /tmp/nerdctl-2.3.5-linux-${cpu_architecture}.tar.gz /usr/local/bin/containerd-rootless.sh /usr/local/bin/containerd-rootless-setuptool.sh
%{ if buildkit_enabled ~}
- wget https://github.com/moby/buildkit/releases/download/v0.32.2/buildkit-v0.32.2.linux-${cpu_architecture}.tar.gz -O /tmp/buildkit-v0.32.2.linux-${cpu_architecture}.tar.gz
- tar Cxzvf /usr/local /tmp/buildkit-v0.32.2.linux-${cpu_architecture}.tar.gz
- rm /tmp/buildkit-v0.32.2.linux-${cpu_architecture}.tar.gz
%{ endif ~}
%{ endif ~}
- systemctl daemon-reload
- systemctl enable --now containerd
%{ if buildkit_enabled ~}
- systemctl enable --now buildkit
%{ endif ~}