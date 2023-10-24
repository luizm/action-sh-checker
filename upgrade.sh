#!/usr/bin/env bash

set -e

if command -v curl >/dev/null; then
  dl="curl -s -K /dev/null"
else
  dl='wget --no-config -qO -'
fi

ALPINE_VER=$(${dl} 'https://registry.hub.docker.com/v2/repositories/library/alpine/tags/' | jq -r '.results[1].name')
GH_VER=$(${dl} https://api.github.com/repos/cli/cli/tags | jq -r '.[0].name')
SHELLCHECK_VER=$(${dl} https://api.github.com/repos/koalaman/shellcheck/tags | jq -r '.[0].name')
SHFMT_VER=$(${dl} https://api.github.com/repos/mvdan/sh/tags | jq -r '.[0].name')

GH_VER="${GH_VER/v}"
SHELLCHECK_VER="${SHELLCHECK_VER/v}"
SHFMT_VER="${SHFMT_VER/v}"

sed -Ei "
s/^(FROM\s+alpine:).*/\1${ALPINE_VER}/;
s/^(ARG\s+gh_version=).*/\1${GH_VER}/;
s/^(ARG\s+shellcheck_version=).*/\1${SHELLCHECK_VER}/;
s/^(ARG\s+shfmt_version=).*/\1${SHFMT_VER}/;
" Dockerfile

git diff
