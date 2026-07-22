#!/usr/bin/env bash
set -euo pipefail

if [ -f /tmp/fe-meta-preexisting ]; then
  echo "Existing FE metadata detected; skipping initial cluster bootstrap."
  exit 0
fi

%{ if fe_config.initial_leader.root_password.shell_source != null ~}
. ${fe_config.initial_leader.root_password.shell_source}
%{ else ~}
ROOT_PW='${fe_config.initial_leader.root_password.literal}'
%{ endif ~}
while ! mysqladmin -s -h127.0.0.1 -P9030 -uroot ping; do echo "mysqld is not alive, retrying in 5 seconds..."; sleep 5; done
echo "SET PASSWORD = PASSWORD('$ROOT_PW');" | mysql -h127.0.0.1 -P9030 -uroot
export MYSQL_PWD="$ROOT_PW"
%{ for fe_follower_fqdn in fe_config.initial_leader.fe_follower_fqdns ~}
mysql -h127.0.0.1 -P9030 -uroot -e "ALTER SYSTEM ADD FOLLOWER '${fe_follower_fqdn}:9010';"
%{ endfor ~}
%{ for be_fqdn in fe_config.initial_leader.be_fqdns ~}
mysql -h127.0.0.1 -P9030 -uroot -e "ALTER SYSTEM ADD BACKEND '${be_fqdn}:9050';"
%{ endfor ~}
%{ for cn_fqdn in fe_config.initial_leader.cn_fqdns ~}
mysql -h127.0.0.1 -P9030 -uroot -e "ALTER SYSTEM ADD COMPUTE NODE '${cn_fqdn}:9050';"
%{ endfor ~}
%{ for user in fe_config.initial_leader.users ~}
echo "CREATE USER '${user.name}' IDENTIFIED BY '${user.password}' DEFAULT ROLE '${user.default_role}';" | mysql -h127.0.0.1 -P9030 -uroot
%{ endfor ~}
unset MYSQL_PWD
