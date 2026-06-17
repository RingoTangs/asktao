#!/bin/bash
# Build the AskTao 1.4 CCS Docker image.
# Expected build host: CentOS 7.9 with Docker daemon access.
set -euo pipefail

IMAGE_NAME="ringotangs/at-1.4-ccs:0.1"
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
require_file "${SCRIPT_DIR}/runccs"
require_file "${SCRIPT_DIR}/ccs/ccs.ini"
require_file "${SCRIPT_DIR}/ccs/pack_data/etc.pak"
require_file "${SCRIPT_DIR}/ccs/pack_data/lib_ccs32.pak"

echo "Building image: ${IMAGE_NAME}"
echo "Base image: ${BASE_IMAGE}"
echo "Source dir: ${SCRIPT_DIR}"
if [ -f /etc/centos-release ]; then
  echo "Build host: $(cat /etc/centos-release)"
fi

cp "${SCRIPT_DIR}/magic_Linux32" "${BUILD_DIR}/magic_Linux32"
cp "${SCRIPT_DIR}/runccs" "${BUILD_DIR}/runccs"
cp -R "${SCRIPT_DIR}/ccs" "${BUILD_DIR}/ccs"

cat > "${BUILD_DIR}/asktao-ccs-entrypoint.sh" <<'EOF'
#!/bin/bash
set -euo pipefail

if [ ! -f /app/runccs ] \
  || [ ! -f /app/magic_Linux32 ] \
  || [ ! -f /app/ccs/ccs.ini ] \
  || [ ! -f /app/ccs/pack_data/etc.pak ] \
  || [ ! -f /app/ccs/pack_data/lib_ccs32.pak ]; then
  echo "Initializing missing /app files from image contents..."
  cp -an /image-app/. /app/
else
  echo "/app has required files; using mounted contents without copying."
fi

escape_sed_replacement() {
  printf '%s' "$1" | sed 's/[\\\/&]/\\&/g'
}

CCS_INI="/app/ccs/ccs.ini"
if [ "${RESET_CONFIG:-}" = "1" ]; then
  echo "RESET_CONFIG=1: restoring ${CCS_INI} from image template..."
  cp -a /image-app/ccs/ccs.ini "${CCS_INI}"
fi

if [ ! -f "${CCS_INI}" ]; then
  echo "ERROR: missing required file: ${CCS_INI}" >&2
  exit 1
fi

if [ ! -f /app/runccs ]; then
  echo "ERROR: missing required file: /app/runccs" >&2
  exit 1
fi

if [ ! -f /app/magic_Linux32 ]; then
  echo "ERROR: missing required file: /app/magic_Linux32" >&2
  exit 1
fi

if [ ! -f /app/ccs/pack_data/etc.pak ]; then
  echo "ERROR: missing required file: /app/ccs/pack_data/etc.pak" >&2
  exit 1
fi

if [ ! -f /app/ccs/pack_data/lib_ccs32.pak ]; then
  echo "ERROR: missing required file: /app/ccs/pack_data/lib_ccs32.pak" >&2
  exit 1
fi

if [ -n "${DB_HOST:-}" ]; then
  sed -i "s/^Host=.*/Host=$(escape_sed_replacement "${DB_HOST}")/" "${CCS_INI}"
fi

if [ -n "${DB_USER:-}" ]; then
  sed -i "s/^User=.*/User=$(escape_sed_replacement "${DB_USER}")/" "${CCS_INI}"
fi

if [ -n "${DB_PASSWORD:-}" ]; then
  sed -i "s/^Password=.*/Password=$(escape_sed_replacement "${DB_PASSWORD}")/" "${CCS_INI}"
fi

if [ -n "${AAA_ADDR:-}" ]; then
  sed -i "s/^AAA_Addr=.*/AAA_Addr=$(escape_sed_replacement "${AAA_ADDR}")/" "${CCS_INI}"
fi

if grep -q '__DB_HOST__' "${CCS_INI}"; then
  echo "ERROR: DB_HOST is required because ${CCS_INI} contains __DB_HOST__" >&2
  exit 1
fi

if grep -q '__DB_USER__' "${CCS_INI}"; then
  echo "ERROR: DB_USER is required because ${CCS_INI} contains __DB_USER__" >&2
  exit 1
fi

if grep -q '__DB_PASSWORD__' "${CCS_INI}"; then
  echo "ERROR: DB_PASSWORD is required because ${CCS_INI} contains __DB_PASSWORD__" >&2
  exit 1
fi

if grep -q '__AAA_ADDR__' "${CCS_INI}"; then
  echo "ERROR: AAA_ADDR is required because ${CCS_INI} contains __AAA_ADDR__" >&2
  exit 1
fi

chmod +x /app/runccs /app/magic_Linux32
cd /app
exec ./runccs
EOF

cat > "${BUILD_DIR}/Dockerfile" <<EOF
FROM ${BASE_IMAGE}

WORKDIR /app

COPY magic_Linux32 /image-app/magic_Linux32
COPY runccs /image-app/runccs
COPY ccs /image-app/ccs
COPY asktao-ccs-entrypoint.sh /usr/local/bin/asktao-ccs-entrypoint.sh

RUN chmod +x /image-app/magic_Linux32 /image-app/runccs /usr/local/bin/asktao-ccs-entrypoint.sh \\
  && test -f /image-app/ccs/ccs.ini \\
  && test -f /image-app/ccs/pack_data/etc.pak \\
  && test -f /image-app/ccs/pack_data/lib_ccs32.pak

EXPOSE 8110 9110

ENTRYPOINT ["/usr/local/bin/asktao-ccs-entrypoint.sh"]
EOF

docker build -t "${IMAGE_NAME}" "${BUILD_DIR}"

echo
echo "Build complete: ${IMAGE_NAME}"
echo
echo "Run with bundled ccs.ini:"
echo "  docker run -it --rm --name at-1.4-ccs -p 8110:8110 -p 9110:9110 -e DB_HOST=your-db-host -e DB_USER=your-db-user -e DB_PASSWORD=your-db-password -e AAA_ADDR=your-aaa-host ${IMAGE_NAME}"
echo
echo "Run with a host directory mounted at /app:"
echo "  docker run -it --rm --name at-1.4-ccs -p 8110:8110 -p 9110:9110 -e DB_HOST=your-db-host -e DB_USER=your-db-user -e DB_PASSWORD=your-db-password -e AAA_ADDR=your-aaa-host -v /data/at-1.4/ccs:/app ${IMAGE_NAME}"
echo
echo "Note: missing /app service files are initialized from the image on container startup."
echo "Existing files in /app are not overwritten, except when RESET_CONFIG=1 restores ccs.ini."
echo "DB_HOST, DB_USER, DB_PASSWORD, and AAA_ADDR replace ccs.ini placeholders when set."
echo "Those values are written to /app/ccs/ccs.ini and persist when /app is a host mount."
