#!/bin/sh
#### sh test/smoke.sh <image> [zitadel-tools version] [platform]

set -e

export MSYS_NO_PATHCONV=1

readonly IMAGE="$1"
readonly VERSION="${2:-}"
readonly PLATFORM="${3:-}"

PLATFORM_ARG=""
if [ -n "${PLATFORM}" ]; then
  PLATFORM_ARG="--platform=${PLATFORM}"
fi

run() {
  docker run --rm ${PLATFORM_ARG} --user 1000:1000 "${IMAGE}" sh -c "$1" # ok: optional
}

fail() {
  echo "FAIL: $1"
  exit 1
}

OUTPUT=$(run "zitadel-tools --version")
echo "${OUTPUT}"
case "${OUTPUT}" in
  *"version dev "*) fail "zitadel-tools was built without its version" ;;
  *"version ${VERSION}"*) echo "ok: zitadel-tools --version" ;;
  *) fail "zitadel-tools --version does not name ${VERSION}" ;;
esac

if [ "$(run "pwd")" != "/data" ]; then
  fail "the working directory is not /data"
fi
echo "ok: working directory /data"

if [ "$(run "zitadel-tools basicauth --id example-id --secret example-secret")" != "ZXhhbXBsZS1pZDpleGFtcGxlLXNlY3JldA==" ]; then
  fail "basicauth"
fi
echo "ok: basicauth"

JWT='^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$'
run "cd /tmp \
  && openssl genrsa -out key.pem 2048 2> /dev/null \
  && openssl rsa -in key.pem -pubout -out key.pub 2> /dev/null \
  && zitadel-tools key2jwt --audience=https://example.com --key=key.pem --issuer=smoke --output=jwt.txt \
  && grep -Eq '${JWT}' jwt.txt \
  && zitadel-tools key2jwt --audience=https://example.com --key=- --issuer=smoke < key.pem | grep -Eq '${JWT}'" \
  || fail "key2jwt with a key created by openssl"
echo "ok: openssl genrsa and key2jwt, from a file and from stdin"

echo "smoke test passed${PLATFORM:+ on ${PLATFORM}}"
