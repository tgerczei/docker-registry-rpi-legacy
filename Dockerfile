# Compile binaries
FROM arm32v6/golang:alpine as builder

ENV DISTRIBUTION_DIR /go/src/github.com/docker/distribution
ENV DOCKER_BUILDTAGS include_oss include_gcs

ARG VERSION=master

RUN set -ex \
        && apk add --no-cache --virtual .build-deps \
                make \
                git \
	&& git clone -b $VERSION https://github.com/docker/distribution.git $DISTRIBUTION_DIR

WORKDIR $DISTRIBUTION_DIR

RUN mkdir -p /etc/docker/registry \
	&& cp cmd/registry/config-dev.yml /etc/docker/registry/config.yml

RUN make PREFIX=/go clean binaries \
	&& apk del --purge .build-deps

# Build a minimal distribution
FROM alpine:latest
label maintainer="Tamás Gérczei <tamas@gerczei.eu>"

COPY --from=builder /go/bin/registry /bin/registry
COPY --from=builder /go/src/github.com/docker/distribution/cmd/registry/config-example.yml /etc/docker/registry/config.yml

VOLUME ["/var/lib/registry"]
EXPOSE 5000
ENTRYPOINT ["/bin/registry"]
CMD ["serve", "/etc/docker/registry/config.yml"]
