#!/bin/bash -e

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

#init ws73
ws73_plat=plat_soc
ws73_wifi=wifi_soc
ws73_sle=sle_soc
ws73_ble=ble_soc

if ! lsmod | grep -q "${ws73_plat}"; then
        insmod /usr/lib/modules/ws73/${ws73_plat}.ko
fi
sleep 0.5

if ! lsmod | grep -q "${ws73_wifi}"; then
	modprobe cfg80211
        insmod /usr/lib/modules/ws73/${ws73_wifi}.ko
fi
sleep 0.5

if ! lsmod | grep -q "${ws73_sle}"; then
        insmod /usr/lib/modules/ws73/${ws73_sle}.ko
fi
sleep 0.5

if ! lsmod | grep -q "${ws73_ble}"; then
        insmod /usr/lib/modules/ws73/${ws73_ble}.ko
fi
