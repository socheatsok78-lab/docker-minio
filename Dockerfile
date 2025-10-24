ARG MINIO_VERSION=latest
ARG MINIO_UPDATE_MINISIGN_PUBKEY=RWTx5Zr1tiHQLwG9keckT0c45M3AGeHD6IvimQHpyRywVWGbP1aVSGav

FROM golang:1.24-alpine AS build

ENV GOPATH=/go
ENV CGO_ENABLED=0

# Install build dependencies and minisign
RUN apk add -U --no-cache ca-certificates git make curl bash \
    && go install aead.dev/minisign/cmd/minisign@v0.2.1

# Build MinIO from source code
ARG TARGETARCH
ARG MINIO_VERSION
ARG MINIO_UPDATE_MINISIGN_PUBKEY

# Download mc binary and signature files
ADD https://dl.min.io/client/mc/release/linux-${TARGETARCH}/mc /go/bin/mc
ADD https://dl.min.io/client/mc/release/linux-${TARGETARCH}/mc.minisig /go/bin/mc.minisig
ADD https://dl.min.io/client/mc/release/linux-${TARGETARCH}/mc.sha256sum /go/bin/mc.sha256sum

# Verify binary signature using public key
RUN minisign -Vqm /go/bin/mc -x /go/bin/mc.minisig -P "${MINIO_UPDATE_MINISIGN_PUBKEY}"

# Clone MinIO source code at the specified version
RUN <<EOT
    if [ "$MINIO_VERSION" == "latest" ]; then
        MINIO_VERSION=master
    fi
    git clone --branch=${MINIO_VERSION} --depth=1 --single-branch https://github.com/minio/minio.git /minio
EOT

WORKDIR /minio
ARG GITHUB_REPOSITORY_OWNER=minio
RUN <<EOT
    GIT_IMPORT="github.com/minio/minio/cmd"
    GIT_COMMIT=$(git rev-parse HEAD)
    GIT_COMMIT_YEAR=$(git show -s --format=%cd --date=format:%Y HEAD)
    GIT_DIRTY=$(test -n "`git status --porcelain`" && echo "+CHANGES" || true)
    GIT_DIRTY=${GIT_DIRTY}${GITHUB_REPOSITORY_OWNER:+"+${GITHUB_REPOSITORY_OWNER}"}
    DATE_FORMAT="%Y-%m-%dT%H:%M:%SZ"
    GIT_DATE=$(date -u +${DATE_FORMAT})

    GOLDFLAGS="-w -s"
    GOLDFLAGS="${GOLDFLAGS} -X ${GIT_IMPORT}.Version=${MINIO_VERSION}"
    GOLDFLAGS="${GOLDFLAGS} -X ${GIT_IMPORT}.CopyrightYear=${GIT_COMMIT_YEAR}"
    GOLDFLAGS="${GOLDFLAGS} -X ${GIT_IMPORT}.ReleaseTag=${GIT_COMMIT:0:12}${GIT_DIRTY}"
    GOLDFLAGS="${GOLDFLAGS} -X ${GIT_IMPORT}.CommitID=${GIT_COMMIT}"
    GOLDFLAGS="${GOLDFLAGS} -X ${GIT_IMPORT}.ShortCommitID=${GIT_COMMIT:0:12}"
    GOLDFLAGS="${GOLDFLAGS} -X ${GIT_IMPORT}.GOPATH=$(go env GOPATH)"
    GOLDFLAGS="${GOLDFLAGS} -X ${GIT_IMPORT}.GOROOT=$(go env GOROOT)"

    (set -x; go build -o /usr/bin/minio -trimpath -ldflags "${GOLDFLAGS}" .)
    (set -x; /usr/bin/minio --version)
EOT

FROM registry.access.redhat.com/ubi9/ubi-micro:latest

ENV MINIO_UPDATE=off
ENV MINIO_CONSOLE_ADDRESS=":9001"

COPY --from=build /usr/bin/minio* /usr/bin/
COPY --from=build /go/bin/mc* /usr/bin/
COPY --from=build /go/bin/curl* /usr/bin/
COPY --from=build /minio/CREDITS /licenses/CREDITS
COPY --from=build /minio/LICENSE /licenses/LICENSE
COPY --from=build /minio/dockerscripts/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh

EXPOSE 9000 9001
VOLUME ["/data"]

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["minio"]
