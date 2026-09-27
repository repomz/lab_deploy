#!/usr/bin/env bash
set -euo pipefail

deploy_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$deploy_dir"

if [[ ! -f .env ]]; then
  echo "Backup aborted: $deploy_dir/.env is missing" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

backup_dir="${BACKUP_DIR:-$deploy_dir/backups}"
retention_days="${BACKUP_RETENTION_DAYS:-14}"
if [[ ! "$retention_days" =~ ^[0-9]+$ ]] || (( retention_days < 1 )); then
  echo "Backup aborted: BACKUP_RETENTION_DAYS must be a positive integer" >&2
  exit 1
fi

install -d -m 0700 "$backup_dir"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
target="$backup_dir/lab-$timestamp.archive.gz"
partial="$target.partial"
trap 'rm -f "$partial"' EXIT

compose=(docker compose -f compose.yaml -f compose.prod.yaml)
"${compose[@]}" exec -T mongo mongodump \
  --archive --gzip \
  --username "${MONGO_ROOT_USERNAME:-lab_admin}" \
  --password "$MONGO_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --db "${MONGO_DATABASE:-lab}" > "$partial"

test -s "$partial"
gzip -t "$partial"
"${compose[@]}" exec -T mongo mongorestore \
  --archive --gzip --dryRun \
  --username "${MONGO_ROOT_USERNAME:-lab_admin}" \
  --password "$MONGO_ROOT_PASSWORD" \
  --authenticationDatabase admin < "$partial" >/dev/null

chmod 0600 "$partial"
mv "$partial" "$target"
trap - EXIT

find "$backup_dir" -type f -name 'lab-*.archive.gz' -mtime "+$retention_days" -delete
echo "Verified MongoDB backup: $target"
