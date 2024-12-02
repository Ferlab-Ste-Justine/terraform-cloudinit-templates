#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if install_dependencies ~}
users:
  - name: fluentbit
    system: true
    lock_passwd: true
    groups: systemd-journal
    sudo: "ALL= NOPASSWD: /bin/systemctl reload fluent-bit.service"
%{ endif ~}

write_files:
%{ if vault_agent_integration.enabled ~}
  - path: ${vault_agent_integration.agent_config_path}/templates/${vault_agent_integration.config_name_prefix}-fluentbit.hcl
    owner: root:root
    permissions: "0444"
    content: |
      template {
        source      = "${vault_agent_integration.secret_path}"
        destination = "/etc/fluent-bit/${vault_agent_integration.config_name_prefix}-config.conf"
        command     = ""
      }
%{ endif ~}
  - path: /etc/fluent-bit-customization/forward_ca.crt
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, fluentbit.forward.ca_cert)}
  - path: /etc/fluent-bit-customization/default-config/default-variables.conf
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, fb_default_variables_conf)}
  - path: /etc/fluent-bit-customization/default-config/service.conf
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, fb_service_conf)}
  - path: /etc/fluent-bit-customization/default-config/inputs.conf
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, fb_inputs_conf)}
  - path: /etc/fluent-bit-customization/default-config/output-default-sources.conf
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, fb_output_default_sources_conf)}
  - path: /etc/fluent-bit-customization/default-config/output-all.conf
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, fb_output_all_conf)}
  - path: /etc/fluent-bit-customization/default-config/static.conf
    owner: root:root
    permissions: "0444"
    content: |
      @INCLUDE /etc/fluent-bit-customization/default-config/default-variables.conf

      @INCLUDE /etc/fluent-bit-customization/default-config/service.conf

      @INCLUDE /etc/fluent-bit-customization/default-config/inputs.conf

      @INCLUDE /etc/fluent-bit-customization/default-config/output-all.conf
  - path: /etc/fluent-bit-customization/default-config/dynamic.conf
    owner: root:root
    permissions: "0444"
    content: |
      @INCLUDE ${dynamic_config.entrypoint_path}
  - path: /usr/local/bin/reload-fluent-bit-configs
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/sh
      FLUENTBIT_STATUS=$(systemctl is-active fluent-bit.service)
      if [ $FLUENTBIT_STATUS = "active" ]; then
        sudo systemctl reload fluent-bit.service
      fi
  - path: /etc/systemd/system/fluent-bit.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description=Fluent Bit
      Documentation=https://docs.fluentbit.io/manual/
      Requires=network.target
      After=network.target

      [Service]
      User=fluentbit
      Group=fluentbit
      Type=simple
      EnvironmentFile=-/etc/sysconfig/fluent-bit
      EnvironmentFile=-/etc/default/fluent-bit
      ExecStart=/opt/fluent-bit/bin/fluent-bit --enable-hot-reload -c /etc/fluent-bit/fluent-bit.conf
      ExecReload=/bin/kill -HUP $MAINPID
      Restart=always

      [Install]
      WantedBy=multi-user.target

%{ if install_dependencies ~}
packages:
  - curl
%{ endif ~}

runcmd:
%{ if install_dependencies ~}
#Install fluentbit
  - curl https://packages.fluentbit.io/fluentbit.key | gpg --dearmor > /usr/share/keyrings/fluentbit-keyring.gpg
  - echo "deb [signed-by=/usr/share/keyrings/fluentbit-keyring.gpg] https://packages.fluentbit.io/$(lsb_release --id --short | tr '[:upper:]' '[:lower:]')/$(lsb_release --codename --short) $(lsb_release --codename --short) main" >> /etc/apt/sources.list 
  - apt-get update
  - apt-get install -y fluent-bit
%{ endif ~}
  - mkdir -p /var/lib/fluent-bit/systemd-db
  - chmod 700 /var/lib/fluent-bit/systemd-db
%{ if dynamic_config.enabled ~}
  - cp /etc/fluent-bit-customization/default-config/dynamic.conf /etc/fluent-bit/fluent-bit.conf
%{ else ~}
  - cp /etc/fluent-bit-customization/default-config/static.conf /etc/fluent-bit/fluent-bit.conf
%{ endif ~}
  - chown -R fluentbit:fluentbit /etc/fluent-bit-customization
  - chown -R fluentbit:fluentbit /etc/fluent-bit
  - chown -R fluentbit:fluentbit /var/lib/fluent-bit
  - systemctl enable fluent-bit.service
  - systemctl start fluent-bit.service