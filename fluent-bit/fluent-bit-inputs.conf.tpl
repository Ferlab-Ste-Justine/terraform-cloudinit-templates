%{ for service in fluentbit.systemd_services ~}
[INPUT]
    Name           systemd
    Tag            ${service.tag}
    Systemd_Filter _SYSTEMD_UNIT=${service.service}
    DB             /var/lib/fluent-bit/systemd-db/${service.tag}
    Mem_Buf_Limit  10MB
%{ endfor ~}