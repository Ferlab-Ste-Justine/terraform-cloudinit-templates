%{ for idx, config in nfs_configs ~}
%{ if config.allowed_ips == "" ~}
${config.path}  127.0.0.1(${config.rw ? "rw" : "ro" },${config.sync ? "sync" : "async"},${config.subtree_check ? "subtree_check" : "no_subtree_check"}${config.no_root_squash ? ",no_root_squash" : ""},insecure)
%{ else ~}
${config.path}  ${config.allowed_ips}(${config.rw ? "rw" : "ro" },${config.sync ? "sync" : "async"},${config.subtree_check ? "subtree_check" : "no_subtree_check"}${config.no_root_squash ? ",no_root_squash" : ""},insecure)
%{ endif ~}
%{ endfor ~}