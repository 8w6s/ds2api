FROM node:24 AS webui-builder

WORKDIR /app/webui
COPY webui/package.json webui/package-lock.json ./
RUN npm ci
COPY config.example.json /app/config.example.json
COPY webui ./
RUN npm run build

FROM golang:1.24 AS go-builder
WORKDIR /app
ARG TARGETOS
ARG TARGETARCH
ARG BUILD_VERSION
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
RUN set -eux; \
    GOOS="${TARGETOS:-$(go env GOOS)}"; \
    GOARCH="${TARGETARCH:-$(go env GOARCH)}"; \
    BUILD_VERSION_RESOLVED="${BUILD_VERSION:-}"; \
    if [ -z "${BUILD_VERSION_RESOLVED}" ] && [ -f VERSION ]; then BUILD_VERSION_RESOLVED="$(cat VERSION | tr -d "[:space:]")"; fi; \
    CGO_ENABLED=0 GOOS="${GOOS}" GOARCH="${GOARCH}" go build -buildvcs=false -ldflags="-s -w -X neutronapi/internal/version.BuildVersion=${BUILD_VERSION_RESOLVED}" -o /out/neutronapi ./cmd/neutronapi

FROM busybox:1.36.1-musl AS busybox-tools

FROM debian:bookworm-slim AS runtime-base
WORKDIR /app
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && groupadd -r neutronapi && useradd -r -g neutronapi -d /app -s /sbin/nologin neutronapi \
    && mkdir -p /app/data /data && chown -R neutronapi:neutronapi /app /data \
    && rm -rf /var/lib/apt/lists/*
COPY --from=busybox-tools /bin/busybox /usr/local/bin/busybox
EXPOSE 5001
CMD ["/usr/local/bin/neutronapi"]

FROM runtime-base AS runtime-from-source
COPY --from=go-builder /out/neutronapi /usr/local/bin/neutronapi

COPY --from=go-builder --chown=neutronapi:neutronapi /app/config.example.json /app/config.example.json
COPY --from=webui-builder --chown=neutronapi:neutronapi /app/static/admin /app/static/admin
USER neutronapi

FROM busybox-tools AS dist-extract
ARG TARGETARCH
COPY dist/docker-input/linux_amd64.tar.gz /tmp/neutronapi_linux_amd64.tar.gz
COPY dist/docker-input/linux_arm64.tar.gz /tmp/neutronapi_linux_arm64.tar.gz
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) ARCHIVE="/tmp/neutronapi_linux_amd64.tar.gz" ;; \
      arm64) ARCHIVE="/tmp/neutronapi_linux_arm64.tar.gz" ;; \
      *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    tar -xzf "${ARCHIVE}" -C /tmp; \
    PKG_DIR="$(find /tmp -maxdepth 1 -type d -name "neutronapi_*_linux_${TARGETARCH}" | head -n1)"; \
    test -n "${PKG_DIR}"; \
    mkdir -p /out/static; \
    cp "${PKG_DIR}/neutronapi" /out/neutronapi; \
    cp "${PKG_DIR}/config.example.json" /out/config.example.json; \
    cp -R "${PKG_DIR}/static/admin" /out/static/admin

FROM runtime-base AS runtime-from-dist
COPY --from=dist-extract /out/neutronapi /usr/local/bin/neutronapi

COPY --from=dist-extract --chown=neutronapi:neutronapi /out/config.example.json /app/config.example.json
COPY --from=dist-extract --chown=neutronapi:neutronapi /out/static/admin /app/static/admin
USER neutronapi

FROM runtime-from-source AS final
