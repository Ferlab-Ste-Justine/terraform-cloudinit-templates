[SERVICE]
    flush           1
    daemon          off
    log_level       info
%{ if fluentbit.metrics.enabled ~}
    http_server     on
%{ else ~}
    http_server     off
%{ endif ~}
    http_listen     0.0.0.0
    http_port       ${fluentbit.metrics.port}
    storage.metrics off

%{ for service in fluentbit.systemd_services ~}
[INPUT]
    Name           systemd
    Tag            ${service.tag}
    Systemd_Filter _SYSTEMD_UNIT=${service.service}
    DB             /var/lib/fluent-bit/systemd-db/${service.tag}
    Mem_Buf_Limit  10MB
%{ endfor ~}

%{ if is_go_template ~}
{{range .}}
[INPUT]
    Name           systemd
    Tag            {{.Tag}}
    Systemd_Filter _SYSTEMD_UNIT={{.Name}}
    DB             /var/lib/fluent-bit/systemd-db/{{.Name}}
    Mem_Buf_Limit  10MB
{{end}}
%{ endif ~}


[OUTPUT]
    Name        forward
    Match       *
    Host        ${fluentbit.forward.domain}
    Port        ${fluentbit.forward.port}
    Shared_Key  ${fluentbit.forward.shared_key}
    tls         on
    tls.verify  on
    tls.ca_file /etc/fluent-bit-customization/forward_ca.crt
