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
  #Patroni tls files for health checks
  - path: /opt/patroni/ca.pem
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, patroni_api.ca_certificate)}
  - path: /opt/patroni/client.pem
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, "${patroni_api.client_certificate}\n${patroni_api.client_key}")}
  #Postgres load balancer haproxy configuration
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
  - systemctl enable docker
  - docker ${container_params.config} run -d --restart=always --name=postgres_load_balancer --network=host -v /opt/haproxy:/usr/local/etc/haproxy:ro -v /opt/patroni:/opt/patroni/:ro %{ if container_params.fluentd != "" }${container_params.fluentd}%{ else }--log-driver=journald%{ endif } haproxy:2.2.14