version: 2
renderer: networkd
ethernets:
%{ for idx, val in network_interfaces ~}
  eth${idx}:
    dhcp4: no
    match:
      macaddress: ${val.mac}
    addresses:
      - ${val.ip}/${val.prefix_length}
%{ if val.gateway != "" ~}
    gateway4: ${val.gateway}
%{ endif ~}
%{ if length(val.dns_servers) > 0 ~}
    nameservers:
      addresses: [${join(",", val.dns_servers)}]
%{ endif ~}
%{ endfor ~}