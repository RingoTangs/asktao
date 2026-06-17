#!/bin/bash
# Package the AskTao 1.4 GS Docker build files for server upload.
set -euo pipefail

PACKAGE_NAME="asktao-1.4-gs.zip"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PACKAGE_PATH="${SCRIPT_DIR}/${PACKAGE_NAME}"

require_file() {
  local path="$1"

  if [ ! -f "${path}" ]; then
    echo "ERROR: missing required file: ${path}" >&2
    exit 1
  fi
}

command -v zip >/dev/null 2>&1 || {
  echo "ERROR: zip command not found" >&2
  exit 1
}

require_file "${SCRIPT_DIR}/build-gs-image.sh"
require_file "${SCRIPT_DIR}/magic_Linux32"
require_file "${SCRIPT_DIR}/rungs"
require_file "${SCRIPT_DIR}/gs/game_server.ini"
require_file "${SCRIPT_DIR}/gs/pack_data/etc.pak"
require_file "${SCRIPT_DIR}/gs/pack_data/lib_gs32.pak"
require_file "${SCRIPT_DIR}/gs/pack_data/server_maps.pak"

rm -f "${PACKAGE_PATH}"

(
  cd "${REPO_ROOT}"
  zip -r "${PACKAGE_PATH}" \
    1.4_server/build-gs-image.sh \
    1.4_server/magic_Linux32 \
    1.4_server/rungs \
    1.4_server/gs
)

echo
echo "Package complete: ${PACKAGE_PATH}"
echo
echo "Upload ${PACKAGE_NAME} to the server with ringotangs/at-centos58:0.1, then run:"
echo "  unzip ${PACKAGE_NAME}"
echo "  cd 1.4_server"
echo "  ./build-gs-image.sh"
