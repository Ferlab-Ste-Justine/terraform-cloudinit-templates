#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if ssh_host_key_rsa.public != "" || ssh_host_key_ecdsa.public != "" ~}
ssh_keys:
%{ if ssh_host_key_rsa.public != "" ~}
  rsa_public: ${ssh_host_key_rsa.public}
  rsa_private: |
    ${indent(4, ssh_host_key_rsa.private)}
%{ endif ~}
%{ if ssh_host_key_ecdsa.public != "" ~}
  ecdsa_public: ${ssh_host_key_ecdsa.public}
  ecdsa_private: |
    ${indent(4, ssh_host_key_ecdsa.private)}
%{ endif ~}
%{ endif ~}

users:
  - name: ${tunnel.ssh.user}
    lock_passwd: true
    no_user_group: true
    shell: "/bin/false"
    ssh_authorized_keys:
      - "${tunnel.ssh.authorized_key}"

write_files:
  - path: /opt/tunnel_ssh_entry
    owner: root:root
    permissions: "0444"
    content: |
      Match User ${tunnel.ssh.user}
        AllowAgentForwarding no
        PermitTTY no
        X11Forwarding no
        PermitOpen ${join(" ", [for entry in tunnel.accesses: "${entry.host}:${entry.port}"])}