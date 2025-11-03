#!/bin/bash
set -e

# Some config, normally don't need to change
REMOTE_CONTAINER="yocto-dev-yocto-1"
LOCAL_CONTAINER="nfs-server"
IMAGE_PATH="/home/yocto/yocto-labs/build/tmp/deploy/images/beaglebone/core-image-minimal-beaglebone.rootfs.tar.xz"
TRANSFER_TMP_DIR="/tmp/rootfs-transfer-tmp-h3j3M2n2b1L6d1"   # a unique name, to avoid conflicts

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] REMOTE_HOST

Transfer and extract rootfs image from remote Docker container to local Docker container which serves NFS.

Arguments:
    REMOTE_HOST    SSH host (e.g., 'user@hostname')

Options:
    -y             Skip confirmation prompt
    -h, --help     Show this help message

EOF
}

update_rootfs() {
    local SKIP_CONFIRM="$1"
    local IMAGE_FILENAME
    IMAGE_FILENAME=$(basename "$IMAGE_PATH")

    echo "Fetching rootfs image to /tmp of local NFS container..."

    # Prepare a clean dedicated transfer directory, to find the correct filename easily.
    # Because of symlinks, the transferred filename will be different from IMAGE_FILENAME.
    docker exec "$LOCAL_CONTAINER" sh -c "rm -rf $TRANSFER_TMP_DIR && mkdir -p $TRANSFER_TMP_DIR"


    local TRANSFER_START_TIME
    TRANSFER_START_TIME=$(date +%s)
    # Transfer the file, follow the symlinks
    ssh "$REMOTE_HOST" "docker cp -L $REMOTE_CONTAINER:$IMAGE_PATH -" | \
        docker cp - "$LOCAL_CONTAINER:$TRANSFER_TMP_DIR/"

    # Get the actual transferred filename
    local TRANSFERRED_FILE
    TRANSFERRED_FILE=$(docker exec "$LOCAL_CONTAINER" sh -c "ls $TRANSFER_TMP_DIR/*.tar.xz 2>/dev/null | head -1")

    # Show transferred file size
    local FILE_SIZE_BYTES
    FILE_SIZE_BYTES=$(docker exec "$LOCAL_CONTAINER" stat -c%s "$TRANSFERRED_FILE")
    local FILE_SIZE_MB=$((FILE_SIZE_BYTES / 1024 / 1024))
    local TRANSFER_END_TIME
    TRANSFER_END_TIME=$(date +%s)
    local TRANSFER_DURATION=$((TRANSFER_END_TIME - TRANSFER_START_TIME))

    echo "Transferred: ${FILE_SIZE_MB} MB in ${TRANSFER_DURATION}s"

    # Confirmation prompt before clearing /nfs
    if [[ "$SKIP_CONFIRM" != "y" ]]; then
        echo ""
        echo "WARNING: All files in /nfs directory will be deleted and overwritten!"
        read -p "Continue? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Operation cancelled."
            docker exec "$LOCAL_CONTAINER" rm -rf "$TRANSFER_TMP_DIR"
            exit 1
        fi
    fi

    echo "Cleaning /nfs and extracting new rootfs..."
    docker exec "$LOCAL_CONTAINER" sh -c "rm -rf /nfs/* /nfs/.[!.]* 2>/dev/null || true"
    docker exec "$LOCAL_CONTAINER" tar -xJf "$TRANSFERRED_FILE" -C /nfs

    echo "Cleaning up temporary files..."
    docker exec "$LOCAL_CONTAINER" rm -rf "$TRANSFER_TMP_DIR"
    echo "Rootfs update completed."
}

main() {
    local SKIP_CONFIRM="n"

    # parse arguments
    if [[ $# -eq 0 ]]; then
        show_help
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
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

    update_rootfs "$SKIP_CONFIRM"
}

main "$@"