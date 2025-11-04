#!/bin/bash
set -e

# Some configuration, normally don't need to change
REMOTE_CONTAINER="yocto-dev-yocto-1"
IMAGE_NAME_PREFIX="core-image-minimal"
IMAGE_SUFFIX="-beaglebone.rootfs.wic.xz"
IMAGE_BASE_DIR="/home/yocto/yocto-labs/build/tmp/deploy/images/beaglebone"

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] REMOTE_HOST

Pull image file from remote Docker container to current directory.

Arguments:
    REMOTE_HOST    SSH host (e.g., 'user@hostname')

Options:
    -i IMAGE_PREFIX    Specify image name prefix (default: core-image-minimal)
                       Full image name will be: <prefix>-beaglebone.rootfs.wic.xz
    -y                 Skip confirmation if file exists
    -h, --help         Show this help message

EOF
}

pull_image() {
    local SKIP_CONFIRM="$1"
    local IMAGE_FILENAME
    IMAGE_FILENAME=$(basename "$IMAGE_PATH")

    # Check if file already exists
    if [[ -f "$IMAGE_FILENAME" ]]; then
        if [[ "$SKIP_CONFIRM" != "y" ]]; then
            echo ""
            echo "WARNING: File '$IMAGE_FILENAME' already exists and will be overwritten!"
            read -p "Continue? (y/N): " -r
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Operation cancelled."
                exit 1
            fi
        fi
    fi

    echo "Pulling image from remote container: $IMAGE_FILENAME"

    local TRANSFER_START_TIME
    TRANSFER_START_TIME=$(date +%s)

    local PART_FILENAME="${IMAGE_FILENAME}.part"

    # Transfer to .part file first
    if ssh "$REMOTE_HOST" "docker cp -L $REMOTE_CONTAINER:$IMAGE_PATH -" | tar -xO > "$PART_FILENAME"; then
        echo "Transfer in progress..."

        # Check if downloaded file is empty
        if [[ ! -s "$PART_FILENAME" ]]; then
            echo "Error: Downloaded file is empty (0 bytes)"
            rm -f "$PART_FILENAME"
            exit 1
        fi

        # Move .part file to final filename on success
        mv "$PART_FILENAME" "$IMAGE_FILENAME"

        local TRANSFER_END_TIME
        TRANSFER_END_TIME=$(date +%s)
        local TRANSFER_DURATION=$((TRANSFER_END_TIME - TRANSFER_START_TIME))

        # Show transferred file size
        local FILE_SIZE_BYTES
        FILE_SIZE_BYTES=$(stat -f%z "$IMAGE_FILENAME" 2>/dev/null || stat -c%s "$IMAGE_FILENAME" 2>/dev/null) # -f%z for macOS, -c%s for Linux
        local FILE_SIZE_MB=$((FILE_SIZE_BYTES / 1024 / 1024))

        echo "Transferred: ${FILE_SIZE_MB} MB in ${TRANSFER_DURATION}s"
        echo "Done! File saved to: $(pwd)/$IMAGE_FILENAME"
    else
        echo "Error: Transfer failed"
        rm -f "$PART_FILENAME"
        exit 1
    fi
}

main() {
    local SKIP_CONFIRM="n"

    # Parse arguments
    if [[ $# -eq 0 ]]; then
        show_help
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -i)
                IMAGE_NAME_PREFIX="$2"
                shift 2
                ;;
            -y)
                SKIP_CONFIRM="y"
                shift
                ;;
            *)
                REMOTE_HOST="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$REMOTE_HOST" ]]; then
        echo "Error: REMOTE_HOST is required"
        show_help
    fi

    # Build IMAGE_PATH after parsing all arguments
    IMAGE_PATH="${IMAGE_BASE_DIR}/${IMAGE_NAME_PREFIX}${IMAGE_SUFFIX}"

    pull_image "$SKIP_CONFIRM"
}

main "$@"