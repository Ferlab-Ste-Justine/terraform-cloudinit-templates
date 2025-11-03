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
    Buffer_Chunk_Size  512k
    Buffer_Max_Size    20M
    Mem_Buf_Limit    64MB

[FILTER]
    Name   record_modifier
    Match  ${file.tag}
    Record hostname $${HOSTNAME}
%{ endfor ~}

%{ if try(fluentbit.http_input.enabled, false) ~}
[INPUT]
    Name                      http
    Listen                    ${fluentbit.http_input.listen}
    Port                      ${fluentbit.http_input.port}
    Tag                       ${fluentbit.http_input.tag}
    Successful_Response_Code  201
    Buffer_Chunk_Size         1M
    Buffer_Max_Size           10M
%{ endif ~}
