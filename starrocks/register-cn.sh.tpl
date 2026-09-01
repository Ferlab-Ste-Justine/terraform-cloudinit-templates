#!/bin/bash
set -e
%{ if cn_config.register.root_password.shell_source != null ~}
. ${cn_config.register.root_password.shell_source}
%{ else ~}
ROOT_PW='${cn_config.register.root_password.literal}'
%{ endif ~}
MY_FQDN=$(hostname -f)
while ! mysqladmin -s -h${cn_config.register.fe_host} -P9030 -uroot -p"$ROOT_PW" ping 2>/dev/null; do
  echo "FE not ready, retrying in 10s..."
  sleep 10
done
mysql -h${cn_config.register.fe_host} -P9030 -uroot -p"$ROOT_PW" \
  -e "ALTER SYSTEM ADD COMPUTE NODE '$MY_FQDN:9050';" 2>&1 || true
