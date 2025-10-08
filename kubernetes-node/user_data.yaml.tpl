#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if docker_registry_auth.enabled ~}
write_files:
  - path: /root/.docker/config.json
    owner: root:root
    permissions: "0600"
    content: |
      {
        "auths": {
          "${docker_registry_auth.url}": {
            "auth": "${base64encode("${docker_registry_auth.username}:${docker_registry_auth.password}")}"
          }
        }
      }
%{ endif ~}

%{ if audit.enabled ~}
write_files:
  - path: ${audit.policy_file_path}
    owner: root:root
    permissions: "0644"
    content: |
      apiVersion: audit.k8s.io/v1
      kind: Policy
      rules:
%{ for r in audit.rules ~}
        - level: ${r.level}
%{ if r.verbs != null && length(r.verbs) > 0 ~}
          verbs: [${join(",", [for v in r.verbs: "\"${v}\""])}]
%{ endif ~}
%{ endfor ~}

  - path: /var/log/kubernetes/audit/kube-apiserver-audit.log
    owner: root:root
    permissions: "0644"
    content: ""
%{ endif ~}

runcmd:
  - /sbin/sysctl -w net.ipv4.conf.all.forwarding=1