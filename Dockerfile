FROM fedora:30 AS builder

RUN dnf install -y libmnl-devel elfutils-libelf-devel pkg-config koji @development-tools && \
    dnf clean all

ARG KERNEL_VERSION
RUN test -n "${KERNEL_VERSION}"

RUN koji download-build --rpm --arch=x86_64 kernel-core-${KERNEL_VERSION} && \
    koji download-build --rpm --arch=x86_64 kernel-devel-${KERNEL_VERSION} && \
    koji download-build --rpm --arch=x86_64 kernel-modules-${KERNEL_VERSION} && \
    dnf install -y kernel-core-${KERNEL_VERSION}.rpm kernel-devel-${KERNEL_VERSION}.rpm kernel-modules-${KERNEL_VERSION}.rpm && \
    rm kernel-core-${KERNEL_VERSION}.rpm kernel-devel-${KERNEL_VERSION}.rpm kernel-modules-${KERNEL_VERSION}.rpm && \
    dnf clean all

ARG WIREGUARD_VERSION
RUN test -n "${WIREGUARD_VERSION}"

RUN curl --fail -LsS https://git.zx2c4.com/wireguard-linux-compat/snapshot/wireguard-linux-compat-${WIREGUARD_VERSION}.tar.xz | tar xJ && \
    cd /wireguard-linux-compat-${WIREGUARD_VERSION}/src && \
    KERNELRELEASE=${KERNEL_VERSION} make -j$(nproc) && \
    DESTDIR=/pkg KERNELRELEASE=${KERNEL_VERSION} INSTALL_MOD_STRIP=1 make install && \
    strip /pkg/usr/bin/wg && \
    mkdir -p /pkg/usr/lib/modules/${KERNEL_VERSION}/extra && \
    mv /usr/lib/modules/${KERNEL_VERSION}/extra/wireguard.ko /pkg/usr/lib/modules/${KERNEL_VERSION}/extra/ && \
    xz /pkg/usr/lib/modules/${KERNEL_VERSION}/extra/wireguard.ko && \
    rm -rf /wireguard-linux-compat-${WIREGUARD_VERSION}

FROM scratch

COPY --from=builder /pkg /
