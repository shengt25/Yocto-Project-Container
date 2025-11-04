#!/bin/bash
set -e

# Some config, normally don't need to change
REMOTE_CONTAINER="yocto-dev-yocto-1"
LOCAL_CONTAINER="nfs-server"
IMAGE_NAME_PREFIX="core-image-minimal"
IMAGE_SUFFIX="-beaglebone.rootfs.tar.xz"
IMAGE_BASE_DIR="/home/yocto/yocto-labs/build/tmp/deploy/images/beaglebone"
TRANSFER_TMP_DIR="/tmp/rootfs-transfer-tmp-h3j3M2n2b1L6d1"   # a unique name, to avoid conflicts

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] REMOTE_HOST

Transfer and extract rootfs image from remote Docker container to local Docker container which serves NFS.

Arguments:
    REMOTE_HOST    SSH host (e.g., 'user@hostname')

Options:
    -i IMAGE_PREFIX    Specify image name prefix (default: core-image-minimal)
                       Full image name will be: <prefix>-beaglebone.rootfs.tar.xz
    -y                 Skip confirmation prompt
    -h, --help         Show this help message

EOF
}

update_rootfs() {
    local SKIP_CONFIRM="$1"
    local IMAGE_FILENAME
    IMAGE_FILENAME=$(basename "$IMAGE_PATH")

    echo "Fetching rootfs image: ${IMAGE_FILENAME}"
    echo "Transferring to /tmp of local NFS container..."

    # Prepare a clean dedicated transfer directory, to find the correct filename easily.
    # Because of symlinks, the transferred filename will be different from IMAGE_FILENAME.
    docker exec "$LOCAL_CONTAINER" sh -c "rm -rf $TRANSFER_TMP_DIR && mkdir -p $TRANSFER_TMP_DIR"

    local PART_DIR="${TRANSFER_TMP_DIR}.part"
    docker exec "$LOCAL_CONTAINER" sh -c "rm -rf $PART_DIR && mkdir -p $PART_DIR"

    local TRANSFER_START_TIME
    TRANSFER_START_TIME=$(date +%s)

    # Transfer the file to .part directory first, follow the symlinks
    if ssh "$REMOTE_HOST" "docker cp -L $REMOTE_CONTAINER:$IMAGE_PATH -" | \
        docker cp - "$LOCAL_CONTAINER:$PART_DIR/"; then
        echo "Transfer in progress..."

        # Get the actual transferred filename
        local TRANSFERRED_FILE
        TRANSFERRED_FILE=$(docker exec "$LOCAL_CONTAINER" sh -c "ls $PART_DIR/*.tar.xz 2>/dev/null | head -1")

        # Check if file was found and is not empty
        if [[ -z "$TRANSFERRED_FILE" ]]; then
            echo "Error: No .tar.xz file found after transfer"
            docker exec "$LOCAL_CONTAINER" rm -rf "$PART_DIR"
            exit 1
        fi

        local FILE_SIZE_BYTES
        FILE_SIZE_BYTES=$(docker exec "$LOCAL_CONTAINER" stat -c%s "$TRANSFERRED_FILE" 2>/dev/null || echo "0")

        if [[ "$FILE_SIZE_BYTES" -eq 0 ]]; then
            echo "Error: Downloaded file is empty (0 bytes)"
            docker exec "$LOCAL_CONTAINER" rm -rf "$PART_DIR"
            exit 1
        fi

        # Move from .part to actual transfer directory on success
        docker exec "$LOCAL_CONTAINER" sh -c "mv $PART_DIR/* $TRANSFER_TMP_DIR/ && rmdir $PART_DIR"

        # Update the transferred file path
        TRANSFERRED_FILE=$(docker exec "$LOCAL_CONTAINER" sh -c "ls $TRANSFER_TMP_DIR/*.tar.xz 2>/dev/null | head -1")

        local FILE_SIZE_MB=$((FILE_SIZE_BYTES / 1024 / 1024))
        local TRANSFER_END_TIME
        TRANSFER_END_TIME=$(date +%s)
        local TRANSFER_DURATION=$((TRANSFER_END_TIME - TRANSFER_START_TIME))

        echo "Transferred: ${FILE_SIZE_MB} MB in ${TRANSFER_DURATION}s"
    else
        echo "Error: Transfer failed"
        docker exec "$LOCAL_CONTAINER" rm -rf "$PART_DIR"
        exit 1
    fi

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

    update_rootfs "$SKIP_CONFIRM"
}

main "$@"