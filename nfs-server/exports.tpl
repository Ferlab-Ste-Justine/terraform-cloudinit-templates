%{ for idx, config in nfs_configs ~}
${config.path}  127.0.0.1(${config.rw ? "rw" : "ro" },${config.sync ? "sync" : "async"},${config.subtree_check ? "subtree_check" : "no_subtree_check"}${config.no_root_squash ? ",no_root_squash" : ""},insecure)
%{ endfor ~}