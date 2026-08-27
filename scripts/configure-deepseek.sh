#!/bin/sh
set -eu

env_file="${1:-/opt/lab/.env}"
if [ ! -f "$env_file" ]; then
  echo "Environment file not found: $env_file" >&2
  exit 1
fi

printf "DeepSeek API key (input hidden): "
restore_echo() { stty echo; }
trap restore_echo EXIT INT TERM
stty -echo
IFS= read -r api_key
stty echo
trap - EXIT INT TERM
printf "\n"

case "$api_key" in
  sk-*) ;;
  *) echo "The key must start with sk-" >&2; exit 1 ;;
esac

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT
awk -v key="$api_key" '
  BEGIN { found = 0 }
  /^DEEPSEEK_API_KEY=/ { print "DEEPSEEK_API_KEY=" key; found = 1; next }
  /^DEEPSEEK_MODEL=/ { print "DEEPSEEK_MODEL=deepseek-v4-flash"; next }
  { print }
  END {
    if (!found) print "DEEPSEEK_API_KEY=" key
  }
' "$env_file" > "$tmp_file"
install -m 600 "$tmp_file" "$env_file"

cd "$(dirname "$env_file")"
docker compose -f compose.yaml -f compose.prod.yaml up -d --no-build --force-recreate backend
echo "DeepSeek configured; backend restarted."
