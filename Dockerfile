###############################################################################
#### Builder
###############################################################################
FROM golang:alpine AS builder

RUN apk add --no-cache git

WORKDIR /tools

RUN go install github.com/zitadel/zitadel-tools@latest

###############################################################################
#### Image
###############################################################################
FROM alpine:latest

ARG BUILD_DATE
LABEL org.label-schema.name="Zitadel Tools" \
      org.label-schema.description="Docker image for Zitadel Tools based on official Alpine image" \
      org.label-schema.vendor="epicsoft LLC / Alexander Schwarz <info@epicsoft.one>" \
      org.label-schema.version=latest \
      org.label-schema.schema-version="1.0" \
      org.label-schema.build-date=${BUILD_DATE}

LABEL image.name="epicsoft_zitadel_tools" \
      image.description="Docker image for Zitadel Tools based on official Alpine image" \
      maintainer="epicsoft LLC" \
      maintainer.name="Alexander Schwarz <info@epicsoft.one>" \
      maintainer.copyright="Copyright 2024-2026 epicsoft LLC / Alexander Schwarz" \
      license="MIT"

RUN apk --no-cache add openssl \
                       ca-certificates \
 && update-ca-certificates \
 && rm -rf /var/cache/apk/*

COPY --from=builder /go/bin/zitadel-tools /usr/local/bin/zitadel-tools

WORKDIR /data

CMD ["zitadel-tools"]
