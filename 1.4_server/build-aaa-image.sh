#!/bin/bash
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

cp "${SCRIPT_DIR}/magic_Linux32" "${BUILD_DIR}/magic_Linux32"
cp "${SCRIPT_DIR}/runaaa" "${BUILD_DIR}/runaaa"
cp -R "${SCRIPT_DIR}/aaa" "${BUILD_DIR}/aaa"

cat > "${BUILD_DIR}/Dockerfile" <<EOF
FROM ${BASE_IMAGE}

WORKDIR /app

COPY magic_Linux32 ./magic_Linux32
COPY runaaa ./runaaa
COPY aaa ./aaa

RUN chmod +x ./magic_Linux32 ./runaaa \\
  && test -f ./aaa/aaa.ini \\
  && test -f ./aaa/pack_data/lib_aaa32.pak

ENTRYPOINT ["./runaaa"]
EOF

docker build -t "${IMAGE_NAME}" "${BUILD_DIR}"

echo
echo "Build complete: ${IMAGE_NAME}"
echo
echo "Run with bundled aaa.ini:"
echo "  docker run --rm --name asktao-aaa ${IMAGE_NAME}"
echo
echo "Run with host 1.4_server mounted at /app:"
echo "  docker run --rm --name asktao-aaa -v \"${SCRIPT_DIR}:/app\" ${IMAGE_NAME}"
echo
echo "Note: the mounted host path must contain the complete 1.4_server directory contents."
echo "An empty host directory will hide the files packaged in the image and startup will fail."
