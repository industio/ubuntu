# shellcheck shell=bash

export BOARD_NAME="IDO EVB3506"
export BOARD_MAKER="industio"
export BOARD_SOC="Rockchip RK3506"
export BOARD_CPU="ARM Cortex A7"
# Build a 32-bit (armhf) userspace to match the 32-bit RK3506 kernel
export ARCH="armhf"
export UBOOT_PACKAGE=""
export UBOOT_RULES_TARGET=""
export UBOOT_RULES_TARGET_EXTRA=""
export COMPATIBLE_SUITES=("jammy")
export COMPATIBLE_FLAVORS=("server")

function config_image_hook__ido-evb3506() {
    local rootfs="$1"
    local overlay="$2"
    local suite="$3"

    if [ "${suite}" == "jammy" ] || [ "${suite}" == "noble" ]; then
	#cp "${overlay}/packages/" "${rootfs}/packages/" -rf
	cp "${overlay}/etc/" "${rootfs}/" -rf
	#cp "${overlay}/system/" "${rootfs}/" -rf
	cp "${overlay}/usr/" "${rootfs}/" -rf
	#cp "${overlay}/vendor/" "${rootfs}/" -rf

        # Install the rockchip camera engine
        #chroot "${rootfs}" apt-get -y install /packages/rkaiq/

        # The ubuntu-server meta packages are normally installed via the
        # live-build package-lists pass; install them here as well in case
        # the cached tarball predates that pass (e.g. an interrupted build)
        if ! chroot "${rootfs}" dpkg -s ubuntu-server > /dev/null 2>&1; then
            chroot "${rootfs}" apt-get -y install ubuntu-server ubuntu-rockchip-settings-server software-properties-common
        fi

	# WiFi BT
        chroot "${rootfs}" systemctl enable rkwifi-bt
        chroot "${rootfs}" systemctl enable bt-set
	chroot "${rootfs}" systemctl enable resize-all
	chroot "${rootfs}" systemctl enable usbdevice

	chroot "${rootfs}" apt-get -y install perl

        echo "IDO_VERSION=B1.0_V1.0.0" >> "${rootfs}/etc/os-release"
	
	rm -f "${rootfs}/etc/debian_chroot"
	echo "industio" > "${rootfs}/etc/hostname"
	sed -i 's/localhost\.localdomain/industio/; s/localhost6\.localdomain6/industio/' "${rootfs}/etc/hosts"
	if [ -e ${rootfs}/lib/systemd/system/oem-config.service ]; then
		mv "${rootfs}/lib/systemd/system/oem-config.service" "${rootfs}/opt/"
		if [ -e ${rootfs}/etc/systemd/system/oem-config.target.wants ]; then
			rm -rf "${rootfs}/etc/systemd/system/oem-config.target.wants"
		fi
	fi

	if [ -e ${rootfs}/etc/systemd/system/default.target ]; then
		rm -f "${rootfs}/etc/systemd/system/default.target"
	fi

	#ln -sf /lib/systemd/system/graphical.target "${rootfs}/etc/systemd/system/default.target"

	
	MID=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
	printf '%s\n' "${MID}" > "${rootfs}/etc/machine-id"
	chmod 444 "${rootfs}/etc/machine-id"

	# add user industio
	chroot "${rootfs}" adduser --disabled-password --gecos "" industio
	HASH=$(openssl passwd -6 '123456')
	chroot "${rootfs}" usermod -p "${HASH}" industio

	chroot "${rootfs}" usermod -aG sudo,adm,audio,video,plugdev,dialout,input,cdrom,dip,users,render industio
	chroot "${rootfs}" usermod -p "${HASH}" root
	if [ -d "${rootfs}/home/oem" ]; then
	    chroot "${rootfs}" deluser --remove-home oem
	fi
	
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
	
	chroot "${rootfs}" apt-get -y install net-tools
	chroot "${rootfs}" apt-get -y install iperf3
	chroot "${rootfs}" apt-get -y install xterm
	chroot "${rootfs}" apt-get -y install samba
	chroot "${rootfs}" apt-get -y install v4l-utils

	# Disable GNOME idle/screen-blank settings (desktop images only, the
	# schemas are not installed on server images)
	if chroot "${rootfs}" gsettings list-schemas 2>/dev/null | grep -q '^org.gnome.desktop.session$'; then
	    chroot "${rootfs}" bash -c 'XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus gsettings set org.gnome.desktop.session idle-delay 0'
	    chroot "${rootfs}" bash -c 'XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus gsettings set org.gnome.desktop.screensaver lock-enabled false'
	    chroot "${rootfs}" bash -c 'XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type nothing'
	    chroot "${rootfs}" bash -c 'XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type nothing'
	fi

	echo "
[industio]
path = /home/industio
available = yes
valid users = industio
read only = no
browsable = yes
public = yes
writable = yes
" >> "${rootfs}/etc/samba/smb.conf"
	
	chroot "${rootfs}" bash -c 'echo -e "123456\n123456" | smbpasswd -a industio'

	#sed -i 's/#  AutomaticLoginEnable = true/AutomaticLoginEnable = true/g' ${rootfs}/etc/gdm3/custom.conf
	#sed -i 's/#  AutomaticLogin = user1/AutomaticLogin = industio/g' ${rootfs}/etc/gdm3/custom.conf

	chroot "${rootfs}" addgroup --system nopasswdlogin
	chroot "${rootfs}" usermod -aG nopasswdlogin industio
	echo "auth sufficient pam_succeed_if.so user ingroup nopasswdlogin" >> ${rootfs}/etc/pam.d/gdm-password

	printf 'SystemMaxUse=32M\nForwardToSyslog=no\n' >> "${rootfs}/etc/systemd/journald.conf"
    fi

    return 0
}
