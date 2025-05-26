%{ for service in fluentbit.systemd_services ~}
[INPUT]
    Name           systemd
    Tag            ${service.tag}
    Systemd_Filter _SYSTEMD_UNIT=${service.service}
    DB             /var/lib/fluent-bit/systemd-services-db/${service.tag}
    Mem_Buf_Limit  10MB
%{ endfor ~}

%{ for file in fluentbit.log_files ~}
[INPUT]
    Name             tail
    Tag              ${file.tag}
    Path             ${file.path}
    Path_Key         path
    DB               /var/lib/fluent-bit/log-files-db/${file.tag}
    Read_from_Head   ${file.read_from_head}
    Skip_Empty_Lines On
    Mem_Buf_Limit    10MB

[FILTER]
    Name   record_modifier
    Match  ${file.tag}
    Record hostname $${HOSTNAME}
%{ endfor ~}
