# shellcheck shell=bash

export BOARD_NAME="IDO EVB6208"
export BOARD_MAKER="industio"
export BOARD_SOC="Rockchip RK3562"
export BOARD_CPU="ARM Cortex A53"
export UBOOT_PACKAGE=""
export UBOOT_RULES_TARGET=""
export UBOOT_RULES_TARGET_EXTRA=""
export COMPATIBLE_SUITES=("jammy")
export COMPATIBLE_FLAVORS=("server" "desktop")

function config_image_hook__ido-evb6208() {
    local rootfs="$1"
    local overlay="$2"
    local suite="$3"

    if [ "${suite}" == "jammy" ] || [ "${suite}" == "noble" ]; then
	cp "${overlay}/packages/" "${rootfs}/packages/" -rf
	cp "${overlay}/etc/" "${rootfs}/" -rf
	cp "${overlay}/system/" "${rootfs}/" -rf
	cp "${overlay}/usr/" "${rootfs}/" -rf
	cp "${overlay}/vendor/" "${rootfs}/" -rf

	# Install libmali
        chroot "${rootfs}" apt-get -y install /packages/libmali/libmali-bifrost-g52-g24p0-x11-wayland-gbm_1.9-1_arm64.deb
        chroot "${rootfs}" apt-get -y install /packages/libmali/libmali-bifrost-g52-g24p0-x11-wayland-gbm-dbgsym_1.9-1_arm64.deb

        # Install the rockchip camera engine
        chroot "${rootfs}" apt-get -y install /packages/rkaiq/camera_engine_rkaiq_rk3562_arm64.deb

	# WiFi BT
        chroot "${rootfs}" systemctl enable rkwifi-bt
        chroot "${rootfs}" systemctl enable bt-set
	chroot "${rootfs}" systemctl enable resize-all

        echo "IDO_VERSION=B1.0_V1.0.0" >> "${rootfs}/etc/os-release"
	
	rm -f "${rootfs}/etc/debian_chroot"
	echo "industio" > "${rootfs}/etc/hostname"
	sed -i 's/localhost\.localdomain/industio/; s/localhost6\.localdomain6/industio/' "${rootfs}/etc/hosts"
	mv "${rootfs}/lib/systemd/system/oem-config.service" "${rootfs}/opt/"
	rm -rf "${rootfs}/etc/systemd/system/oem-config.target.wants"
	rm -f "${rootfs}/etc/systemd/system/default.target"
	ln -sf /lib/systemd/system/graphical.target "${rootfs}/etc/systemd/system/default.target"
    fi

    return 0
}
