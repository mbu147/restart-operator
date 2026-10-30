# Build stage
FROM --platform=$BUILDPLATFORM golang:1.27 AS builder

ARG TARGETOS
ARG TARGETARCH

WORKDIR /workspace

# Copy Go module files
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

# Copy source code
COPY cmd/ cmd/
COPY pkg/ pkg/
COPY hack/ hack/

# Build the operator binary
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} go build -ldflags="-s -w" -o manager cmd/main.go

# Runtime stage
FROM gcr.io/distroless/static:nonroot

WORKDIR /

# Copy the operator binary
COPY --from=builder /workspace/manager .

# Use nonroot user for security
USER 65532:65532

# Expose metrics and health probe ports
EXPOSE 8080 8081

ENTRYPOINT ["/manager"]