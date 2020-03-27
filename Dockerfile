FROM alpine:latest
LABEL "name"="sh-checker"
LABEL "maintainer"="Luiz Muller <contact@luizm.dev>"

ENV shfmt_version 3.0.1
ENV shellcheck_version 0.7.0
ENV temp_packages curl tar xz

RUN apk add --no-cache bash
RUN apk add --no-cache $temp_packages
RUN curl -Ls "https://github.com/mvdan/sh/releases/download/v2.6.4/shfmt_v${shfmt_version}_linux_amd64" -o /usr/local/bin/shfmt && \
    chmod +x /usr/local/bin/shfmt
RUN	curl -Ls "https://shellcheck.storage.googleapis.com/shellcheck-v${shellcheck_version}.linux.x86_64.tar.xz" -o /tmp/shellcheck.tgz && \
    cd /tmp && tar -xf shellcheck.tgz && \
    mv shellcheck-v${shellcheck_version}/shellcheck /usr/local/bin/ && \
    chmod +x /usr/local/bin/shellcheck

RUN apk del $temp_packages
RUN rm -rf /tmp/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
