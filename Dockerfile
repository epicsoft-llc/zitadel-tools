###############################################################################
#### Builder
###############################################################################
FROM golang:alpine AS builder

ARG ZITADEL_TOOLS_VERSION="latest"
ARG BUILD_DATE="development"

#### the ldflags of the upstream release build - without them 'zitadel-tools --version' says "dev"
RUN case "${ZITADEL_TOOLS_VERSION}" in latest|v*) query="${ZITADEL_TOOLS_VERSION}" ;; *) query="v${ZITADEL_TOOLS_VERSION}" ;; esac \
 && version=$(go list -m -f '{{.Version}}' "github.com/zitadel/zitadel-tools@${query}") \
 && commit=$(go list -m -f '{{with .Origin}}{{.Hash}}{{end}}' "github.com/zitadel/zitadel-tools@${version}") \
 && CGO_ENABLED=0 go install -trimpath \
      -ldflags "-s -w -X main.version=${version#v} -X main.commit=${commit:-none} -X main.date=${BUILD_DATE}" \
      "github.com/zitadel/zitadel-tools@${version}"

###############################################################################
#### Image
###############################################################################
FROM alpine:latest

ARG ZITADEL_TOOLS_VERSION="latest"
ARG BUILD_DATE="development"
LABEL org.label-schema.name="ZITADEL Tools" \
      org.label-schema.description="ZITADEL Tools (key2jwt, basicauth, migrate) with OpenSSL on Alpine - multi-platform, rebuilt weekly" \
      org.label-schema.vendor="epicsoft LLC / Alexander Schwarz <info@epicsoft.one>" \
      org.label-schema.url="https://gitlab.com/epicsoft-networks/zitadel-tools" \
      org.label-schema.vcs-url="https://gitlab.com/epicsoft-networks/zitadel-tools/-/tree/main" \
      org.label-schema.version=${ZITADEL_TOOLS_VERSION} \
      org.label-schema.schema-version="1.0" \
      org.label-schema.build-date=${BUILD_DATE}

LABEL image.name="epicsoft_zitadel_tools" \
      image.description="ZITADEL Tools (key2jwt, basicauth, migrate) with OpenSSL on Alpine - multi-platform, rebuilt weekly" \
      image.zitadel-tools.version=${ZITADEL_TOOLS_VERSION} \
      maintainer="epicsoft LLC" \
      maintainer.name="Alexander Schwarz <info@epicsoft.one>" \
      maintainer.copyright="Copyright 2024-2026 epicsoft LLC / Alexander Schwarz" \
      license="MIT"

#### packages of the base image lag behind the Alpine repository - the upgrade brings their security fixes
RUN apk --no-cache upgrade \
 && apk --no-cache add openssl \
                       ca-certificates

COPY --from=builder /go/bin/zitadel-tools /usr/local/bin/zitadel-tools

WORKDIR /data

CMD ["zitadel-tools"]
