[OUTPUT]
    Name        forward
    Match       *
    Host        ${fluentbit.forward.domain}
    Port        ${fluentbit.forward.port}
    Shared_Key  ${fluentbit.forward.shared_key}
    tls         on
    tls.verify  on
    tls.ca_file /etc/fluent-bit-customization/forward_ca.crt