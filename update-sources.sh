#!/usr/bin/env bash
#
# Regenerate caddy2-<version>.tar.gz and vendor.tar.gz for the caddy2
# OBS package, and keep the spec's Version: in sync.
#
# Requires: go >= 1.25 and network access to proxy.golang.org.
#
# Usage:
#   ./update-sources.sh                          # defaults: 2.10.1 / master
#   CADDY_VERSION=2.10.2 ./update-sources.sh     # bump Caddy
#   RATELIMIT_REF=<git-sha> ./update-sources.sh  # pin the rate-limit module
#                                                 # (only stale tags upstream,
#                                                 # master tracks development)
set -euo pipefail

CADDY_VERSION="${CADDY_VERSION:-2.10.1}"
RATELIMIT_REF="${RATELIMIT_REF:-master}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}/src"

echo "==> Pinning caddy v${CADDY_VERSION}, caddy-ratelimit @ ${RATELIMIT_REF}"
rm -f go.sum
go get "github.com/caddyserver/caddy/v2@v${CADDY_VERSION}" \
       "github.com/mholt/caddy-ratelimit@${RATELIMIT_REF}"
go mod tidy
# drop any "toolchain" line so OBS builders with exactly go 1.25 don't
# try to fetch a newer toolchain (GOTOOLCHAIN=local in the spec guards this too)
go mod edit -toolchain=none
go mod verify

echo "==> Building caddy2-${CADDY_VERSION}.tar.gz"
STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT
mkdir -p "${STAGE}/caddy2-${CADDY_VERSION}"
cp -p main.go go.mod go.sum "${STAGE}/caddy2-${CADDY_VERSION}/"
# ship Caddy's license text; taken from the module cache, no extra fetch
cp -p "$(go env GOMODCACHE)/github.com/caddyserver/caddy/v2@v${CADDY_VERSION}/LICENSE" \
      "${STAGE}/caddy2-${CADDY_VERSION}/LICENSE"
rm -f "${ROOT}"/caddy2-*.tar.gz
tar -C "${STAGE}" --owner=0 --group=0 --numeric-owner \
    -czf "${ROOT}/caddy2-${CADDY_VERSION}.tar.gz" "caddy2-${CADDY_VERSION}"

echo "==> Building vendor.tar.gz"
go mod vendor
tar -C "${ROOT}/src" --owner=0 --group=0 --numeric-owner \
    -czf "${ROOT}/vendor.tar.gz" vendor
rm -rf vendor

sed -i "s/^Version:.*/Version:        ${CADDY_VERSION}/" "${ROOT}/caddy2.spec"

echo "==> Done. Next steps:"
echo "    osc addremove"
echo "    osc commit    # the go_modules service will refresh vendor.tar.gz"
