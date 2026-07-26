#!/usr/bin/env bash
set -euo pipefail

META_DIR="${meta_dir}"
FE_START="/opt/starrocks/${install_dir}/bin/start_fe.sh"
SEED_HOSTS="${join(" ", seed_hosts)}"
SELF_HOST="${self_host}"

meta_present() {
  [ -e "$META_DIR/image/ROLE" ] || [ -e "$META_DIR/ROLE" ] || ls "$META_DIR/bdb/"*.jdb >/dev/null 2>&1
}

established_peer() {
  local p body
  for p in $SEED_HOSTS; do
    [ "$p" = "$SELF_HOST" ] && continue
    body="$(curl -fsS -m 3 "http://$p:8030/api/bootstrap" 2>/dev/null || true)"
    case "$body" in
      *'"status":"OK"'*) echo "$p"; return 0 ;;
    esac
  done
  return 1
}

if meta_present; then
  echo "guarded-start: existing metadata present, starting normally"
  exec "$FE_START" --host_type FQDN
fi

echo "guarded-start: metadata empty, probing peers for an established cluster"
peer=""
for _ in $(seq 1 40); do
  if peer="$(established_peer)"; then break; fi
  peer=""
  sleep 3
done

if [ -n "$peer" ]; then
  echo "guarded-start: joining established cluster via $peer"
  exec "$FE_START" --helper "$peer:9010" --host_type FQDN
fi

%{ if initial_cluster ~}
echo "guarded-start: no established peer and initial_cluster=true, seeding a new cluster"
touch /opt/starrocks/.fe-seeded
exec "$FE_START" --host_type FQDN
%{ else ~}
echo "guarded-start: FATAL empty metadata, no established peer, node is not part of the initial cluster; refusing to cold-bootstrap (anti split-brain)" >&2
exit 1
%{ endif ~}
