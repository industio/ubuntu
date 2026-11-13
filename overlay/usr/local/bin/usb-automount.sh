#!/bin/bash

ACTION=$1
DEV_NAME=$2
MOUNT_POINT="/media/${DEV_NAME}"

if [ "$ACTION" == "add" ]; then
        mkdir -p "${MOUNT_POINT}"
        FS_TYPE=$(blkid -o value -s TYPE /dev/${DEV_NAME})

        if [ "${FS_TYPE}" == "exfat" ]; then
                mount.exfat-fuse -o allow_other,utf8 /dev/${DEV_NAME} "${MOUNT_POINT}"
        elif [ "${FS_TYPE}" == "vfat" ]; then
                mount -o iocharset=utf8 /dev/${DEV_NAME} "${MOUNT_POINT}"
        elif [ "${FS_TYPE}" == "ntfs" ]; then
                mount -o iocharset=utf8,umask=000 /dev/${DEV_NAME} "${MOUNT_POINT}"
        else
                mount /dev/${DEV_NAME} "${MOUNT_POINT}"
        fi


elif [ "$ACTION" == "remove" ]; then
        umount -l "${MOUNT_POINT}"

        if [ -d "${MOUNT_POINT}" ]; then
                rmdir "${MOUNT_POINT}"
        fi
fi
