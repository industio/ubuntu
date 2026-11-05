#!/bin/bash -e

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin


sleep 1
if ! lsmod | grep -q "aic8800_bsp"; then
                insmod /system/lib/modules/aic8800_bsp.ko aic_fw_path="/vendor/etc/firmware/"
fi

if ! lsmod | grep -q "aic8800_fdrv"; then
                insmod /system/lib/modules/aic8800_fdrv.ko
fi

exit 0
