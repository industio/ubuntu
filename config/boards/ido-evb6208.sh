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
	
	MID=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
	printf '%s\n' "${MID}" > "${rootfs}/etc/machine-id"
	chmod 444 "${rootfs}/etc/machine-id"

	# add user industio
	chroot "${rootfs}" adduser --disabled-password --gecos "" industio
	HASH=$(openssl passwd -6 '123456')
	chroot "${rootfs}" usermod -p "${HASH}" industio

	chroot "${rootfs}" usermod -aG sudo,adm,audio,video,plugdev,netdev,dialout,input,cdrom,dip,users,render,bluetooth,lpadmin industio
	chroot "${rootfs}" usermod -p "${HASH}" root
	chroot "${rootfs}" deluser --remove-home oem
	
	rm -f "${rootfs}/etc/systemd/system/getty.target.wants/getty@tty1.service"

	mkdir -p "${rootfs}/etc/systemd/system/serial-getty@ttyFIQ0.service.d"
	cat > "${rootfs}/etc/systemd/system/serial-getty@ttyFIQ0.service.d/baud.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -- \\u' --keep-baud 1500000,115200,57600,38400,9600 ttyFIQ0 $TERM
EOF
	ln -sf /lib/systemd/system/serial-getty@.service \
	    "${rootfs}/etc/systemd/system/getty.target.wants/serial-getty@ttyFIQ0.service"

	ln -sf /dev/null "${rootfs}/etc/udev/rules.d/80-net-setup-link.rules"

	printf 'SystemMaxUse=32M\nForwardToSyslog=no\n' >> "${rootfs}/etc/systemd/journald.conf"
    fi

    return 0
}
