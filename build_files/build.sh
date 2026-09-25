#!/bin/bash

set -ouex pipefail

IMAGE_VARIANT="${IMAGE_VARIANT:-main}"

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Shared across all images
for script in /ctx/shared/*.sh; do
    echo "::group:: ===$(basename "$script")==="
    bash "$script"
    echo "::endgroup::"
done

### Variant specific (main / nvidia)
if [[ -f "/ctx/variants/${IMAGE_VARIANT}.sh" ]]; then
    echo "::group:: ===variant ${IMAGE_VARIANT}==="
    bash "/ctx/variants/${IMAGE_VARIANT}.sh"
    echo "::endgroup::"
fi
