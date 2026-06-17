#!/bin/bash
# Build the AskTao 1.4 GS Docker image.
# Expected build host: CentOS 7.9 with Docker daemon access.
set -euo pipefail

IMAGE_NAME="ringotangs/at-1.4-gs:0.1"
BASE_IMAGE="ringotangs/at-centos58:0.1"
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
require_file "${SCRIPT_DIR}/rungs"
require_file "${SCRIPT_DIR}/gs/game_server.ini"
require_file "${SCRIPT_DIR}/gs/pack_data/etc.pak"
require_file "${SCRIPT_DIR}/gs/pack_data/lib_gs32.pak"
require_file "${SCRIPT_DIR}/gs/pack_data/server_maps.pak"

echo "Building image: ${IMAGE_NAME}"
echo "Base image: ${BASE_IMAGE}"
echo "Source dir: ${SCRIPT_DIR}"
if [ -f /etc/centos-release ]; then
  echo "Build host: $(cat /etc/centos-release)"
fi

cp "${SCRIPT_DIR}/magic_Linux32" "${BUILD_DIR}/magic_Linux32"
cp "${SCRIPT_DIR}/rungs" "${BUILD_DIR}/rungs"
cp -R "${SCRIPT_DIR}/gs" "${BUILD_DIR}/gs"

cat > "${BUILD_DIR}/asktao-gs-entrypoint.sh" <<'EOF'
#!/bin/bash
set -euo pipefail

if [ ! -f /app/rungs ] \
  || [ ! -f /app/magic_Linux32 ] \
  || [ ! -f /app/gs/game_server.ini ] \
  || [ ! -f /app/gs/pack_data/etc.pak ] \
  || [ ! -f /app/gs/pack_data/lib_gs32.pak ] \
  || [ ! -f /app/gs/pack_data/server_maps.pak ]; then
  echo "Initializing missing /app files from image contents..."
  cp -an /image-app/. /app/
else
  echo "/app has required files; using mounted contents without copying."
fi

GS_INI="/app/gs/game_server.ini"
if [ "${RESET_CONFIG:-}" = "1" ]; then
  echo "RESET_CONFIG=1: restoring ${GS_INI} from image template..."
  cp -a /image-app/gs/game_server.ini "${GS_INI}"
fi

if [ ! -f "${GS_INI}" ]; then
  echo "ERROR: missing required file: ${GS_INI}" >&2
  exit 1
fi

if [ ! -f /app/rungs ]; then
  echo "ERROR: missing required file: /app/rungs" >&2
  exit 1
fi

if [ ! -f /app/magic_Linux32 ]; then
  echo "ERROR: missing required file: /app/magic_Linux32" >&2
  exit 1
fi

if [ ! -f /app/gs/pack_data/etc.pak ]; then
  echo "ERROR: missing required file: /app/gs/pack_data/etc.pak" >&2
  exit 1
fi

if [ ! -f /app/gs/pack_data/lib_gs32.pak ]; then
  echo "ERROR: missing required file: /app/gs/pack_data/lib_gs32.pak" >&2
  exit 1
fi

if [ ! -f /app/gs/pack_data/server_maps.pak ]; then
  echo "ERROR: missing required file: /app/gs/pack_data/server_maps.pak" >&2
  exit 1
fi

command -v python >/dev/null 2>&1 || {
  echo "ERROR: python command not found; it is required to update GBK game_server.ini" >&2
  exit 1
}

python -c 'import codecs; codecs.lookup("gbk")' >/dev/null 2>&1 || {
  echo "ERROR: python gbk codec not found; it is required to update game_server.ini" >&2
  exit 1
}

python - <<'PY'
# -*- coding: utf-8 -*-
import os
import sys

try:
    text_type = unicode
except NameError:
    text_type = str

path = "/app/gs/game_server.ini"
env_to_key = (
    ("GS_NAME", "Name"),
    ("AAA_ADDR", "AAA_Addr"),
)
placeholder_to_env = (
    ("__GS_NAME__", "GS_NAME"),
    ("__AAA_ADDR__", "AAA_ADDR"),
)

def read_gbk(path):
    fh = open(path, "rb")
    try:
        data = fh.read()
    finally:
        fh.close()
    return data.decode("gbk")

def write_gbk(path, text):
    fh = open(path, "wb")
    try:
        fh.write(text.encode("gbk"))
    finally:
        fh.close()

def get_env_text(name):
    value = os.environ.get(name)
    if not value:
        return None
    if isinstance(value, text_type):
        return value
    return value.decode("utf-8")

text = read_gbk(path)

lines = text.splitlines(True)
for env_name, key in env_to_key:
    value = get_env_text(env_name)
    if value:
        prefix = key + "="
        spaced_prefix = key + " ="
        replaced = False
        for index, line in enumerate(lines):
            newline = u""
            body = line
            if body.endswith(u"\r\n"):
                body = body[:-2]
                newline = u"\r\n"
            elif body.endswith(u"\n"):
                body = body[:-1]
                newline = u"\n"
            if body.startswith(prefix) or body.startswith(spaced_prefix):
                if " =" in body:
                    lines[index] = key + u" = " + value + newline
                else:
                    lines[index] = key + u"=" + value + newline
                replaced = True
        if not replaced:
            sys.stderr.write("ERROR: missing key %s in %s\n" % (key, path))
            sys.exit(1)

text = u"".join(lines)
for placeholder, env_name in placeholder_to_env:
    if placeholder in text:
        sys.stderr.write("ERROR: %s is required because %s contains %s\n" % (env_name, path, placeholder))
        sys.exit(1)

write_gbk(path, text)
PY

chmod +x /app/rungs /app/magic_Linux32
cd /app
exec ./rungs
EOF

cat > "${BUILD_DIR}/Dockerfile" <<EOF
FROM ${BASE_IMAGE}

WORKDIR /app

COPY magic_Linux32 /image-app/magic_Linux32
COPY rungs /image-app/rungs
COPY gs /image-app/gs
COPY asktao-gs-entrypoint.sh /usr/local/bin/asktao-gs-entrypoint.sh

RUN chmod +x /image-app/magic_Linux32 /image-app/rungs /usr/local/bin/asktao-gs-entrypoint.sh \\
  && command -v python >/dev/null 2>&1 \\
  && python -c 'import codecs; codecs.lookup("gbk")' \\
  && test -f /image-app/gs/game_server.ini \\
  && test -f /image-app/gs/pack_data/etc.pak \\
  && test -f /image-app/gs/pack_data/lib_gs32.pak \\
  && test -f /image-app/gs/pack_data/server_maps.pak

ENTRYPOINT ["/usr/local/bin/asktao-gs-entrypoint.sh"]
EOF

docker build -t "${IMAGE_NAME}" "${BUILD_DIR}"

echo
echo "Build complete: ${IMAGE_NAME}"
echo
echo "Run with bundled game_server.ini:"
echo "  docker run -it --rm --name at-1.4-gs1 -p 8160:8160 -e GS_NAME=your-gs-name -e AAA_ADDR=your-aaa-host ${IMAGE_NAME}"
echo
echo "Run with a host directory mounted at /app:"
echo "  docker run -it --rm --name at-1.4-gs1 -p 8160:8160 -e GS_NAME=your-gs-name -e AAA_ADDR=your-aaa-host -v /data/at-1.4/gs:/app ${IMAGE_NAME}"
echo
echo "Note: missing /app service files are initialized from the image on container startup."
echo "Existing files in /app are not overwritten, except when RESET_CONFIG=1 restores game_server.ini."
echo "GS_NAME and AAA_ADDR replace game_server.ini placeholders when set."
echo "game_server.ini is read and written as GBK, so GS_NAME may contain Chinese text."
echo "Those values are written to /app/gs/game_server.ini and persist when /app is a host mount."
