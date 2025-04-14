.:53 {
%{ for bind_address in dns.dns_bind_addresses ~}
    bind ${bind_address}
%{ endfor ~}
    auto {
        directory /opt/coredns/zonefiles (.*) {1}
        reload ${dns.zonefiles_reload_interval}
    }

%{ for forward in dns.forwards ~}
    forward ${forward.domain_name} ${join(" ", forward.dns_servers)}
%{ endfor ~}

%{ if length(dns.cache.domains) > 0 ~}
    cache ${dns.cache.max_ttl} ${join(" ", dns.cache.domains)} {
%{ if dns.cache.prefetch.amount != "" ~}
        prefetch ${dns.cache.prefetch.amount} ${dns.cache.prefetch.duration}
%{ endif ~}
    }
%{ endif ~}

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