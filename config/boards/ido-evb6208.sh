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
        
	# Install libmali
        chroot "${rootfs}" apt-get -y install /packages/libmali/libmali-bifrost-g52-g24p0-x11-wayland-gbm_1.9-1_arm64.deb
        chroot "${rootfs}" apt-get -y install /packages/libmali/libmali-bifrost-g52-g24p0-x11-wayland-gbm-dbgsym_1.9-1_arm64.deb

        # Install the rockchip camera engine
        chroot "${rootfs}" apt-get -y install /packages/rkaiq/camera_engine_rkaiq_rk3562_arm64.deb

        echo "IDO_VERSION=B1.0_V1.0.0" >> "${rootfs}/etc/os-release"
    fi

    return 0
}
