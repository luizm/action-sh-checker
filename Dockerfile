FROM alpine:3.16.0
LABEL "name"="sh-checker"
LABEL "maintainer"="Luiz Muller <contact@luizm.dev>"

ARG shfmt_version=3.6.0
ARG shellcheck_version=0.9.0
ARG gh_version=2.23.0

RUN apk add --no-cache bash git jq curl checkbashisms xz \
    && apk add --no-cache --virtual .build-deps tar \
    && wget "https://github.com/mvdan/sh/releases/download/v${shfmt_version}/shfmt_v${shfmt_version}_linux_amd64" -O /usr/local/bin/shfmt \
    && chmod +x /usr/local/bin/shfmt \
    && wget "https://github.com/koalaman/shellcheck/releases/download/v${shellcheck_version}/shellcheck-v${shellcheck_version}.linux.x86_64.tar.xz"  -O- | tar xJ -C /usr/local/bin/ --strip-components=1 --wildcards '*/shellcheck' \
    && chmod +x /usr/local/bin/shellcheck \
    && curl -L https://github.com/cli/cli/releases/download/v${gh_version}/gh_${gh_version}_linux_amd64.tar.gz | tar xz -C /usr/local/ --strip-components=1 \
    && apk del --no-cache .build-deps \
    && rm -rf /tmp/*

# https://github.com/actions/runner-images/issues/6775#issuecomment-1410270956
RUN git config --system --add safe.directory /github/workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
