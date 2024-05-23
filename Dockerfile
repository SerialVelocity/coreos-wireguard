FROM fedora:30 AS builder

RUN dnf install -y @development-tools xz && \
    dnf clean all

ARG WIREGUARD_TOOLS_VERSION
RUN test -n "${WIREGUARD_TOOLS_VERSION}"

RUN curl --fail -LsS https://git.zx2c4.com/wireguard-tools/snapshot/wireguard-tools-${WIREGUARD_TOOLS_VERSION}.tar.xz | tar xJ && \
    cd /wireguard-tools-${WIREGUARD_TOOLS_VERSION}/src && \
    make -j$(nproc) && \
    DESTDIR=/pkg make install && \
    strip /pkg/usr/bin/wg && \
    rm -rf /wireguard-tools-${WIREGUARD_TOOLS_VERSION}

FROM scratch

COPY --from=builder /pkg /
