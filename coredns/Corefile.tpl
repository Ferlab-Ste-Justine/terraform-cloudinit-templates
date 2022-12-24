.:53 {
%{ for bind_address in dns.dns_bind_addresses ~}
    bind ${bind_address}
%{ endfor ~}
    auto {
        directory /opt/coredns/zonefiles (.*) {1}
        reload ${dns.zonefiles_reload_interval}
    }
%{ if length(dns.alternate_dns_servers) > 0 ~}
    alternate original SERVFAIL . ${join(" ", [for server in dns.alternate_dns_servers: "${server}:53"])}
%{ endif ~}
%{ if dns.load_balance_records ~}
    loadbalance round_robin
%{ endif ~}
    reload 5s
    loop
    nsid ${dns.nsid}
    prometheus ${dns.observability_bind_address}:9153
    health ${dns.observability_bind_address}:8080
    errors
    log
}