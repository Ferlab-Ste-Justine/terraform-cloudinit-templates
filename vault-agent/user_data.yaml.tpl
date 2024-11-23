#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies ~}
users:
  - name: vault
    system: true
    lock_passwd: true
%{ endif ~}

write_files:
  # Vault Agent Role ID
  - path: /etc/vault-agent.d/role-id
    owner: root:root
    permissions: "0644"
    content: "${vault_agent.auth_method.config.role_id}"

  # Vault Agent Secret ID
  - path: /etc/vault-agent.d/secret-id
    owner: root:root
    permissions: "0644"
    content: "${vault_agent.auth_method.config.secret_id}"

  # Vault Agent CA Certificate
  - path: /etc/vault-agent.d/tls/ca.crt
    owner: root:root
    permissions: "0440"
    content: |
      ${vault_agent.vault_ca_cert}

  # Vault Agent configuration
  - path: /etc/vault-agent.d/agent.hcl
    owner: root:root
    permissions: "0644"
    content: |
      exit_after_auth = false
      pid_file = "/var/run/vault-agent.pid"

      auto_auth {
        method "${vault_agent.auth_method.type}" {
          config = {
            role_id_file_path = "/etc/vault-agent.d/role-id"
            secret_id_file_path = "/etc/vault-agent.d/secret-id"
            remove_secret_id_file_after_reading = false
          }
        }

        sink "file" {
          config = {
            path = "/etc/vault-agent.d/agent-token"
          }
        }
      }

      vault {
        address = "${vault_agent.vault_address}"
        ca_cert = "/etc/vault-agent.d/tls/ca.crt"
      }

      auto_reload {
        enabled = true
      }

%{ for template in vault_agent.templates ~}
      template {
        source      = "${template.source_path}"
        destination = "${template.destination_path}"
        command     = "systemctl restart ${template.service_name}"
      }
%{ endfor ~}

%{ if vault_agent.agent_config != "" ~}
      ${vault_agent.agent_config}
%{ endif ~}

  # Vault Agent systemd service configuration
  - path: /etc/systemd/system/vault-agent.service
    owner: root:root
    permissions: "0644"
    content: |
      [Unit]
      Description=Vault Agent
      Requires=network-online.target
      After=network-online.target

      [Service]
      ExecStart=/usr/local/bin/vault agent -config=/etc/vault-agent.d/agent.hcl
      Restart=always
      RestartSec=5
      User=root
      Group=root

      [Install]
      WantedBy=multi-user.target

%{ for template in vault_agent.templates ~}
  # Template content for ${template.source_path}
  - path: ${template.source_path}
    owner: root:root
    permissions: "0644"
    content: |
      {{- with secret "${template.secret_path}" -}}
      {{- .Data.data.${template.secret_key} -}}
      {{- end -}}
%{ endfor ~}

%{ if install_dependencies ~}
packages:
  - unzip
%{ endif ~}

runcmd:
%{ if install_dependencies ~}
  # Vault Installation
  - curl -O https://releases.hashicorp.com/vault/${vault_agent.release_version}/vault_${vault_agent.release_version}_linux_amd64.zip
  - unzip vault_${vault_agent.release_version}_linux_amd64.zip
  - mv vault /usr/local/bin/
%{ endif ~}
  - mkdir -p /etc/vault-agent.d/tls
  - chown -R vault:vault /etc/vault-agent.d
  - systemctl enable vault-agent.service
  - systemctl start vault-agent.service
  