#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
  #Container registry configs
%{ if container_registry.url != "" ~}
  - path: /opt/docker/config.json
    owner: root:root
    permissions: "0440"
    content: |
      {
        "auths": {
          "${container_registry.url}": {
            "auth": "${base64encode(join("", [container_registry.username, ":", container_registry.password]))}"
          }
        }
      }
%{ endif ~}
  #Vault tls files for health checks
  - path: /opt/vault/ca.crt
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, tls.ca_certificate)}
%{ if tls.client_auth ~}
  - path: /opt/vault/client.pem
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, "${tls.client_certificate}\n${tls.client_key}")}
%{ endif ~}
  #Vault load balancer haproxy configuration
  - path: /opt/haproxy/haproxy.cfg
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, haproxy_config)}

%{ if install_dependencies ~}
packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg-agent
  - software-properties-common
%{ endif ~}

runcmd:
  #Install load balancer as a background docker container
%{ if install_dependencies ~}
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  - add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io
%{ endif ~}
  - chown -R www-data:www-data /opt/haproxy
  - chown -R www-data:www-data /opt/vault
  - systemctl enable docker
  - docker ${container_params.config} run -d --restart=always --name=vault_load_balancer --user www-data -v /opt/haproxy:/usr/local/etc/haproxy:ro -v /opt/vault:/opt/vault/:ro -p 80:80 -p 443:443 --sysctl net.ipv4.ip_unprivileged_port_start=0 ${container_params.fluentd} haproxy:2.7.6