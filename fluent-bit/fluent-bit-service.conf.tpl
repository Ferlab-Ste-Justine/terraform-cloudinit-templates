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
