#!/bin/bash
# Build the AskTao 1.4 DBA Docker image.
# Expected build host: CentOS 7.9 with Docker daemon access.
set -euo pipefail

IMAGE_NAME="ringotangs/at-1.4-dba:0.1"
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
require_file "${SCRIPT_DIR}/rundba"
require_file "${SCRIPT_DIR}/dba/dba.ini"
require_file "${SCRIPT_DIR}/dba/pack_data/etc.pak"
require_file "${SCRIPT_DIR}/dba/pack_data/lib_dba32.pak"

echo "Building image: ${IMAGE_NAME}"
echo "Base image: ${BASE_IMAGE}"
echo "Source dir: ${SCRIPT_DIR}"
if [ -f /etc/centos-release ]; then
  echo "Build host: $(cat /etc/centos-release)"
fi

cp "${SCRIPT_DIR}/magic_Linux32" "${BUILD_DIR}/magic_Linux32"
cp "${SCRIPT_DIR}/rundba" "${BUILD_DIR}/rundba"
cp -R "${SCRIPT_DIR}/dba" "${BUILD_DIR}/dba"

cat > "${BUILD_DIR}/asktao-dba-entrypoint.sh" <<'EOF'
#!/bin/bash
set -euo pipefail

if [ -z "$(find /app -mindepth 1 -maxdepth 1 -print -quit)" ]; then
  echo "Initializing empty /app from image contents..."
  cp -a /image-app/. /app/
else
  echo "/app is not empty; using mounted contents without overwriting."
fi

if [ ! -f /app/rundba ]; then
  echo "ERROR: missing required file: /app/rundba" >&2
  exit 1
fi

if [ ! -f /app/magic_Linux32 ]; then
  echo "ERROR: missing required file: /app/magic_Linux32" >&2
  exit 1
fi

if [ ! -f /app/dba/pack_data/etc.pak ]; then
  echo "ERROR: missing required file: /app/dba/pack_data/etc.pak" >&2
  exit 1
fi

if [ ! -f /app/dba/pack_data/lib_dba32.pak ]; then
  echo "ERROR: missing required file: /app/dba/pack_data/lib_dba32.pak" >&2
  exit 1
fi

escape_sed_replacement() {
  printf '%s' "$1" | sed 's/[\\\/&]/\\&/g'
}

DBA_INI="/app/dba/dba.ini"
if [ ! -f "${DBA_INI}" ]; then
  echo "ERROR: missing required file: ${DBA_INI}" >&2
  exit 1
fi

if [ -n "${DB_HOST:-}" ]; then
  sed -i "s/^Host=.*/Host=$(escape_sed_replacement "${DB_HOST}")/" "${DBA_INI}"
fi

if [ -n "${DB_USER:-}" ]; then
  sed -i "s/^User=.*/User=$(escape_sed_replacement "${DB_USER}")/" "${DBA_INI}"
fi

if [ -n "${DB_PASSWORD:-}" ]; then
  sed -i "s/^Password=.*/Password=$(escape_sed_replacement "${DB_PASSWORD}")/" "${DBA_INI}"
fi

if [ -n "${AAA_ADDR:-}" ]; then
  sed -i "s/^AAA_Addr=.*/AAA_Addr=$(escape_sed_replacement "${AAA_ADDR}")/" "${DBA_INI}"
fi

if grep -q '__DB_HOST__' "${DBA_INI}"; then
  echo "ERROR: DB_HOST is required because ${DBA_INI} contains __DB_HOST__" >&2
  exit 1
fi

if grep -q '__DB_USER__' "${DBA_INI}"; then
  echo "ERROR: DB_USER is required because ${DBA_INI} contains __DB_USER__" >&2
  exit 1
fi

if grep -q '__DB_PASSWORD__' "${DBA_INI}"; then
  echo "ERROR: DB_PASSWORD is required because ${DBA_INI} contains __DB_PASSWORD__" >&2
  exit 1
fi

if grep -q '__AAA_ADDR__' "${DBA_INI}"; then
  echo "ERROR: AAA_ADDR is required because ${DBA_INI} contains __AAA_ADDR__" >&2
  exit 1
fi

chmod +x /app/rundba /app/magic_Linux32
cd /app
exec ./rundba
EOF

cat > "${BUILD_DIR}/Dockerfile" <<EOF
FROM ${BASE_IMAGE}

WORKDIR /app

COPY magic_Linux32 /image-app/magic_Linux32
COPY rundba /image-app/rundba
COPY dba /image-app/dba
COPY asktao-dba-entrypoint.sh /usr/local/bin/asktao-dba-entrypoint.sh

RUN chmod +x /image-app/magic_Linux32 /image-app/rundba /usr/local/bin/asktao-dba-entrypoint.sh \\
  && test -f /image-app/dba/dba.ini \\
  && test -f /image-app/dba/pack_data/etc.pak \\
  && test -f /image-app/dba/pack_data/lib_dba32.pak

EXPOSE 8120 9120

ENTRYPOINT ["/usr/local/bin/asktao-dba-entrypoint.sh"]
EOF

docker build -t "${IMAGE_NAME}" "${BUILD_DIR}"

echo
echo "Build complete: ${IMAGE_NAME}"
echo
echo "Run with bundled dba.ini:"
echo "  docker run -it --rm --name at-1.4-dba -p 8120:8120 -p 9120:9120 -e DB_HOST=your-db-host -e DB_USER=your-db-user -e DB_PASSWORD=your-db-password -e AAA_ADDR=your-aaa-host ${IMAGE_NAME}"
echo
echo "Run with a host directory mounted at /app:"
echo "  docker run -it --rm --name at-1.4-dba -p 8120:8120 -p 9120:9120 -e DB_HOST=your-db-host -e DB_USER=your-db-user -e DB_PASSWORD=your-db-password -e AAA_ADDR=your-aaa-host -v /data/at-1.4/dba:/app ${IMAGE_NAME}"
echo
echo "Note: an empty /app mount is initialized from the image on container startup."
echo "A non-empty /app mount is used as-is and will not be overwritten."
echo "DB_HOST, DB_USER, DB_PASSWORD, and AAA_ADDR replace dba.ini placeholders when set."
