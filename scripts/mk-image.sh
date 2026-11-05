#!/bin/bash -e

TARGET_ROOTFS_DIR=$1
ROOTFSIMAGE=$2


echo Making rootfs!

if [ -e ${ROOTFSIMAGE} ]; then
	sudo rm ${ROOTFSIMAGE}
fi

# Apparent size + maxium alignment(file_count * block_size) + maxium journal size
IMAGE_SIZE_MB=$(( $(sudo du --apparent-size -sm ${TARGET_ROOTFS_DIR} | cut -f1) + \
	$(sudo find ${TARGET_ROOTFS_DIR} | wc -l) * 4 / 1024 + 64 ))

# Extra 10%
IMAGE_SIZE_MB=$(( $IMAGE_SIZE_MB * 110 / 100 ))

sudo mkfs.ext4 -d ${TARGET_ROOTFS_DIR} ${ROOTFSIMAGE} ${IMAGE_SIZE_MB}M

echo Rootfs Image: ${ROOTFSIMAGE}
