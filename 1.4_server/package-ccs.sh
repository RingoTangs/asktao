#!/bin/bash
# Package the AskTao 1.4 CCS Docker build files for server upload.
set -euo pipefail

PACKAGE_NAME="asktao-1.4-ccs.zip"
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

require_file "${SCRIPT_DIR}/build-ccs-image.sh"
require_file "${SCRIPT_DIR}/magic_Linux32"
require_file "${SCRIPT_DIR}/runccs"
require_file "${SCRIPT_DIR}/ccs/ccs.ini"
require_file "${SCRIPT_DIR}/ccs/pack_data/etc.pak"
require_file "${SCRIPT_DIR}/ccs/pack_data/lib_ccs32.pak"

rm -f "${PACKAGE_PATH}"

(
  cd "${REPO_ROOT}"
  zip -r "${PACKAGE_PATH}" \
    1.4_server/build-ccs-image.sh \
    1.4_server/magic_Linux32 \
    1.4_server/runccs \
    1.4_server/ccs
)

echo
echo "Package complete: ${PACKAGE_PATH}"
echo
echo "Upload ${PACKAGE_NAME} to the CentOS 7.9 server, then run:"
echo "  unzip ${PACKAGE_NAME}"
echo "  cd 1.4_server"
echo "  ./build-ccs-image.sh"
