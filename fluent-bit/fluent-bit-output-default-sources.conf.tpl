[OUTPUT]
    Name        forward
    Match_Regex ${"(?:${join("|", [for service in fluentbit.systemd_services: service.tag])})"}
    Host        ${fluentbit.forward.domain}
    Port        ${fluentbit.forward.port}
    Shared_Key  $${output_forward_shared_key}
    tls         on
    tls.verify  on
    tls.ca_file /etc/fluent-bit-customization/forward_ca.crt