#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEPLOY_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
ENV_FILE="$DEPLOY_DIR/.env"

random_hex() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
  else
    od -An -N32 -tx1 /dev/urandom | tr -d ' \n'
  fi
}

read_value() {
  key=$1
  if [ -f "$ENV_FILE" ]; then
    awk -F= -v key="$key" '$1 == key {sub(/^[^=]*=/, ""); print; exit}' "$ENV_FILE"
  fi
}

mongo_password=$(read_value MONGO_ROOT_PASSWORD)
jwt_secret=$(read_value JWT_SECRET)
deepseek_key=$(read_value DEEPSEEK_API_KEY)
public_port=$(read_value PUBLIC_PORT)
public_base_url=$(read_value PUBLIC_BASE_URL)
cors_origins=$(read_value CORS_ORIGINS)
backend_image=$(read_value BACKEND_IMAGE)
frontend_image=$(read_value FRONTEND_IMAGE)

case "$mongo_password" in
  ""|replace-*) mongo_password=$(random_hex) ;;
esac
case "$jwt_secret" in
  ""|replace-*) jwt_secret=$(random_hex) ;;
esac
[ -n "$public_port" ] || public_port=8081
[ -n "$public_base_url" ] || public_base_url="http://localhost:$public_port"
[ -n "$cors_origins" ] || cors_origins="$public_base_url"

umask 077
tmp_file="$ENV_FILE.tmp.$$"
trap 'rm -f "$tmp_file"' EXIT HUP INT TERM
cat > "$tmp_file" <<EOF
MONGO_ROOT_USERNAME=lab_admin
MONGO_ROOT_PASSWORD=$mongo_password
MONGO_DATABASE=lab
JWT_SECRET=$jwt_secret
PUBLIC_PORT=$public_port
PUBLIC_BASE_URL=$public_base_url
CORS_ORIGINS=$cors_origins
MAX_UPLOAD_MB=20
DEEPSEEK_API_KEY=$deepseek_key
DEEPSEEK_BASE_URL=https://api.deepseek.com
DEEPSEEK_MODEL=deepseek-v4-flash
TESSERACT_LANG=rus+eng
BACKEND_IMAGE=$backend_image
FRONTEND_IMAGE=$frontend_image
EOF
mv "$tmp_file" "$ENV_FILE"
trap - EXIT HUP INT TERM
chmod 600 "$ENV_FILE"

echo "Environment is ready: $ENV_FILE"
