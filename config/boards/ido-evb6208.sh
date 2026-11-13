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

	# Install xserver
	chroot "${rootfs}" apt-get -y install /packages/xserver/libgcrypt20_1.10.1-3+deb12u1_arm64.deb
	chroot "${rootfs}" apt-get -y install /packages/xserver/xserver-common_21.1.7-3+deb12u2_all.deb
	chroot "${rootfs}" apt-get -y install /packages/xserver/xserver-xorg-core_21.1.7-3+deb12u2_arm64.deb
	chroot "${rootfs}" apt-get -y install /packages/xserver/xserver-xorg-legacy_21.1.7-3+deb12u2_arm64.deb
	chroot "${rootfs}" apt-get -y install /packages/xserver/xserver-xorg-core-dbgsym_21.1.7-3+deb12u2_arm64.deb
	chroot "${rootfs}" apt-get -y install /packages/xserver/xserver-xorg-legacy-dbgsym_21.1.7-3+deb12u2_arm64.deb
	# Install libmali
        chroot "${rootfs}" apt-get -y install /packages/libmali/libmali-bifrost-g52-g24p0-x11-wayland-gbm_1.9-1_arm64.deb
        chroot "${rootfs}" apt-get -y install /packages/libmali/libmali-bifrost-g52-g24p0-x11-wayland-gbm-dbgsym_1.9-1_arm64.deb

        # Install the rockchip camera engine
        chroot "${rootfs}" apt-get -y install /packages/rkaiq/camera_engine_rkaiq_rk3562_arm64.deb

        chroot "${rootfs}" apt-get -y install libevent-dev libre2-dev libminizip-dev
        chroot "${rootfs}" tar -xvf /usr/local/qt5/lib/libQt5WebEngineCore.so.5.15.8.tar.gz -C /usr/local/qt5/lib/
        chroot "${rootfs}" rm /usr/local/qt5/lib/libQt5WebEngineCore.so.5.15.8.tar.gz

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

	ln -sf /lib/systemd/system/graphical.target "${rootfs}/etc/systemd/system/default.target"

	
	MID=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
	printf '%s\n' "${MID}" > "${rootfs}/etc/machine-id"
	chmod 444 "${rootfs}/etc/machine-id"

	# add user industio
	chroot "${rootfs}" adduser --disabled-password --gecos "" industio
	HASH=$(openssl passwd -6 '123456')
	chroot "${rootfs}" usermod -p "${HASH}" industio

	chroot "${rootfs}" usermod -aG sudo,adm,audio,video,plugdev,dialout,input,cdrom,dip,users,render industio
	chroot "${rootfs}" usermod -p "${HASH}" root
	chroot "${rootfs}" /bin/sh -c '[ -d /home/oem ] && deluser --remove-home oem'
	
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

	chroot "${rootfs}" bash -c 'XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus gsettings set org.gnome.desktop.session idle-delay 0'
	chroot "${rootfs}" bash -c 'XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus gsettings set org.gnome.desktop.screensaver lock-enabled false'
	chroot "${rootfs}" bash -c 'XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type nothing'
	chroot "${rootfs}" bash -c 'XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type nothing'

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

	sed -i 's/WaylandEnable=true/WaylandEnable=false/g' ${rootfs}/etc/gdm3/custom.conf

	# Disable glamor GPU accel for X11: stock glamor's GLES format handling
	# does not match the Mali DDK's channel order, so with libmali installed
	# the desktop shows R/B swapped colors (blue becomes red). Force CPU
	# rendering (AccelMethod none) to keep colors correct.
	mkdir -p "${rootfs}/etc/X11/xorg.conf.d"
	cat > "${rootfs}/etc/X11/xorg.conf.d/20-modesetting.conf" << 'EOF'
### Use Rockchip DRM driver
Section "OutputClass"
    Identifier  "RockchipDRM"
    MatchDriver "rockchip"
    Option      "PrimaryGPU"     "yes"
EndSection

Section "Device"
    Identifier  "Rockchip Graphics"
    Driver      "modesetting"

### Use Rockchip RGA 2D HW accel
#    Option      "AccelMethod"    "exa"

### Use GPU HW accel
    Option      "AccelMethod"    "glamor"

    Option      "DRI"            "2"

### Set to "always" to avoid tearing, could lead to up 50% performance loss
    Option      "FlipFB"         "always"

### Limit flip rate and drop frames for "FlipFB" to reduce performance lost
#    Option      "MaxFlipRate"    "60"

    Option      "NoEDID"         "true"
    Option      "UseGammaLUT"    "true"

### Set virtual screen size (scaled by VOP hardware)
#    Option "VirtualSize" "DSI-1:600x1080"

### Set physical display paddings <top,bottom,left,right>
#    Option "Padding" "DSI-1:180,300,300,540"

EndSection

Section "Screen"
    Identifier  "Default Screen"
    Device      "Rockchip Graphics"
    Monitor     "Default Monitor"
EndSection

### Valid values for rotation are "normal", "left", "right"
Section "Monitor"
    Identifier  "Default Monitor"
    Option      "Rotate"         "normal"
EndSection
EOF

	sed -i 's/#  AutomaticLoginEnable = true/AutomaticLoginEnable = true/g' ${rootfs}/etc/gdm3/custom.conf
	sed -i 's/#  AutomaticLogin = user1/AutomaticLogin = industio/g' ${rootfs}/etc/gdm3/custom.conf

	chroot "${rootfs}" addgroup --system nopasswdlogin
	chroot "${rootfs}" usermod -aG nopasswdlogin industio
	echo "auth sufficient pam_succeed_if.so user ingroup nopasswdlogin" >> ${rootfs}/etc/pam.d/gdm-password

	printf 'SystemMaxUse=32M\nForwardToSyslog=no\n' >> "${rootfs}/etc/systemd/journald.conf"
    fi

    return 0
}
