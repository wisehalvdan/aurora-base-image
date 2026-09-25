# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# Base Image
## One Containerfile, several images. The CI matrix in .github/workflows/build.yml
## passes BASE_IMAGE and IMAGE_VARIANT for each machine:
#   - Intel laptop (no dGPU): ghcr.io/ublue-os/aurora-dx:stable              (IMAGE_VARIANT=main)
#   - RTX 3090 desktop:       ghcr.io/ublue-os/aurora-dx-nvidia-open:stable  (IMAGE_VARIANT=nvidia)
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
ARG BASE_IMAGE=ghcr.io/ublue-os/aurora-dx:stable
FROM ${BASE_IMAGE}

ARG IMAGE_VARIANT=main

### MODIFICATIONS
## Shared changes live in build_files/shared/*.sh, per-variant changes in
## build_files/variants/<IMAGE_VARIANT>.sh. build.sh runs them in order.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    IMAGE_VARIANT="${IMAGE_VARIANT}" /ctx/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
