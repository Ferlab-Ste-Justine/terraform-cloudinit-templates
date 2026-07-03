#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
%{ for shell_source in shell_sources ~}
  - path: ${shell_source.script_path}
    owner: root:root
    permissions: "0440"
    content: |
%{ for secret in shell_source.secrets ~}
      ${secret.variable_name}=$(aws secretsmanager get-secret-value --region ${region} --secret-id ${secret.secret_id} --query SecretString --output text)
%{ endfor ~}