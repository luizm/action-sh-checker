FROM alpine:latest
LABEL "name"="sh-checker"
LABEL "maintainer"="Luiz Muller <contact@luizm.dev>"

ARG shfmt_version 3.0.1
ARG shellcheck_version 0.7.0

RUN apk add --no-cache bash jq curl
RUN apk add --no-cache --virtual .build-deps tar xz
RUN curl -Ls "https://github.com/mvdan/sh/releases/download/v${shfmt_version}/shfmt_v${shfmt_version}_linux_amd64" -o /usr/local/bin/shfmt && \
    chmod +x /usr/local/bin/shfmt
RUN	curl -Ls "https://shellcheck.storage.googleapis.com/shellcheck-v${shellcheck_version}.linux.x86_64.tar.xz" -o /tmp/shellcheck.tgz && \
    cd /tmp && tar -xf shellcheck.tgz && \
    mv shellcheck-v${shellcheck_version}/shellcheck /usr/local/bin/ && \
    chmod +x /usr/local/bin/shellcheck

RUN apk del .build-deps
RUN rm -rf /tmp/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
