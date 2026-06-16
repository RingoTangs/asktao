#!/bin/bash
# Build the AskTao 1.4 AAA Docker image.
# Expected build host: CentOS 7.9 with Docker daemon access.
set -euo pipefail

IMAGE_NAME="ringotangs/at-1.4-aaa:0.1"
BASE_IMAGE="ringotangs/at-centos79:0.1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${BUILD_DIR}"
}
trap cleanup EXIT

require_file() {
  local path="$1"

  if [ ! -f "${path}" ]; then
    echo "ERROR: missing required file: ${path}" >&2
    exit 1
  fi
}

command -v docker >/dev/null 2>&1 || {
  echo "ERROR: docker command not found" >&2
  exit 1
}

require_file "${SCRIPT_DIR}/magic_Linux32"
require_file "${SCRIPT_DIR}/runaaa"
require_file "${SCRIPT_DIR}/aaa/aaa.ini"
require_file "${SCRIPT_DIR}/aaa/pack_data/lib_aaa32.pak"

echo "Building image: ${IMAGE_NAME}"
echo "Base image: ${BASE_IMAGE}"
echo "Source dir: ${SCRIPT_DIR}"
if [ -f /etc/centos-release ]; then
  echo "Build host: $(cat /etc/centos-release)"
fi

cp "${SCRIPT_DIR}/magic_Linux32" "${BUILD_DIR}/magic_Linux32"
cp "${SCRIPT_DIR}/runaaa" "${BUILD_DIR}/runaaa"
cp -R "${SCRIPT_DIR}/aaa" "${BUILD_DIR}/aaa"

cat > "${BUILD_DIR}/asktao-aaa-entrypoint.sh" <<'EOF'
#!/bin/bash
set -euo pipefail

if [ -z "$(find /app -mindepth 1 -maxdepth 1 -print -quit)" ]; then
  echo "Initializing empty /app from image contents..."
  cp -a /image-app/. /app/
else
  echo "/app is not empty; using mounted contents without overwriting."
fi

if [ ! -f /app/runaaa ]; then
  echo "ERROR: missing required file: /app/runaaa" >&2
  exit 1
fi

if [ ! -f /app/magic_Linux32 ]; then
  echo "ERROR: missing required file: /app/magic_Linux32" >&2
  exit 1
fi

if [ ! -f /app/aaa/pack_data/lib_aaa32.pak ]; then
  echo "ERROR: missing required file: /app/aaa/pack_data/lib_aaa32.pak" >&2
  exit 1
fi

escape_sed_replacement() {
  printf '%s' "$1" | sed 's/[\/&]/\\&/g'
}

AAA_INI="/app/aaa/aaa.ini"
if [ ! -f "${AAA_INI}" ]; then
  echo "ERROR: missing required file: ${AAA_INI}" >&2
  exit 1
fi

if [ -n "${DB_HOST:-}" ]; then
  sed -i "s/^Host=.*/Host=$(escape_sed_replacement "${DB_HOST}")/" "${AAA_INI}"
fi

if [ -n "${DB_USER:-}" ]; then
  sed -i "s/^User=.*/User=$(escape_sed_replacement "${DB_USER}")/" "${AAA_INI}"
fi

if [ -n "${DB_PASSWORD:-}" ]; then
  sed -i "s/^Password=.*/Password=$(escape_sed_replacement "${DB_PASSWORD}")/" "${AAA_INI}"
fi

if grep -q '__DB_HOST__' "${AAA_INI}"; then
  echo "ERROR: DB_HOST is required because ${AAA_INI} contains __DB_HOST__" >&2
  exit 1
fi

if grep -q '__DB_USER__' "${AAA_INI}"; then
  echo "ERROR: DB_USER is required because ${AAA_INI} contains __DB_USER__" >&2
  exit 1
fi

if grep -q '__DB_PASSWORD__' "${AAA_INI}"; then
  echo "ERROR: DB_PASSWORD is required because ${AAA_INI} contains __DB_PASSWORD__" >&2
  exit 1
fi

chmod +x /app/runaaa /app/magic_Linux32
cd /app
exec ./runaaa
EOF

cat > "${BUILD_DIR}/Dockerfile" <<EOF
FROM ${BASE_IMAGE}

WORKDIR /app

COPY magic_Linux32 /image-app/magic_Linux32
COPY runaaa /image-app/runaaa
COPY aaa /image-app/aaa
COPY asktao-aaa-entrypoint.sh /usr/local/bin/asktao-aaa-entrypoint.sh

RUN chmod +x /image-app/magic_Linux32 /image-app/runaaa /usr/local/bin/asktao-aaa-entrypoint.sh \\
  && test -f /image-app/aaa/aaa.ini \\
  && test -f /image-app/aaa/pack_data/lib_aaa32.pak

EXPOSE 8101 9101

ENTRYPOINT ["/usr/local/bin/asktao-aaa-entrypoint.sh"]
EOF

docker build -t "${IMAGE_NAME}" "${BUILD_DIR}"

echo
echo "Build complete: ${IMAGE_NAME}"
echo
echo "Run with bundled aaa.ini:"
echo "  docker run --rm --name at-1.4-aaa -p 8101:8101 -p 9101:9101 ${IMAGE_NAME}"
echo
echo "Run with a host directory mounted at /app:"
echo "  docker run --rm --name at-1.4-aaa -p 8101:8101 -p 9101:9101 -e DB_HOST=your-db-host -e DB_USER=your-db-user -e DB_PASSWORD=your-db-password -v /data/at-1.4/aaa:/app ${IMAGE_NAME}"
echo
echo "Note: an empty /app mount is initialized from the image on container startup."
echo "A non-empty /app mount is used as-is and will not be overwritten."
echo "DB_HOST, DB_USER, and DB_PASSWORD replace Host/User/Password in /app/aaa/aaa.ini when set."
