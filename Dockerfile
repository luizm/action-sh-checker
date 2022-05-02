FROM alpine:3.12.3
LABEL "name"="sh-checker"
LABEL "maintainer"="Luiz Muller <contact@luizm.dev>"

ARG shfmt_version=3.4.3
ARG shellcheck_version=0.8.0

RUN apk add --no-cache bash git jq curl checkbashisms \
    && apk add --no-cache --virtual .build-deps tar \
    && wget "https://github.com/mvdan/sh/releases/download/v${shfmt_version}/shfmt_v${shfmt_version}_linux_amd64" -O /usr/local/bin/shfmt \
    && chmod +x /usr/local/bin/shfmt \
    && wget "https://github.com/koalaman/shellcheck/releases/download/v${shellcheck_version}/shellcheck-v${shellcheck_version}.linux.x86_64.tar.xz"  -O- | tar xJ -C /usr/local/bin/ --strip-components=1 --wildcards '*/shellcheck' \
    && chmod +x /usr/local/bin/shellcheck \
    && apk del --no-cache .build-deps \
    && rm -rf /tmp/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
