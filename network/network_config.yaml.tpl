version: 2
renderer: networkd
ethernets:
%{ for idx, val in network_interfaces ~}
  eth${idx}:
    set-name: eth${idx}
%{ if val.ip != "" ~}
    dhcp4: no
%{ else ~}
    dhcp4: yes
%{ endif ~}
    match:
      macaddress: ${val.mac}
%{ if val.ip != "" ~}
    addresses:
      - ${val.ip}/${val.prefix_length}
%{ endif ~}
%{ if val.gateway != "" ~}
    gateway4: ${val.gateway}
%{ endif ~}
%{ if length(val.dns_servers) > 0 ~}
    nameservers:
      addresses: [${join(",", val.dns_servers)}]
%{ endif ~}
%{ endfor ~}