#!/bin/sh
# убунтутач24/003: the m52xq hardware layer for a Lomiri-only postmarketOS rootfs (no Plasma), merged into ./layer
# from (in this order, later wins):
#   1. архив/.v42-zip-stage rootfs-files (our built programs, firmware, services) minus everything Plasma/KDE
#   2. phone-layer/ (taken read-only from the phone: what the installer added there — modem firmware from the modem
#      partition, BT address, sensor registry — and services that came with the base image, e.g. m52xq-usbnet)
#      minus Plasma, keeping from etc/systemd/system only our units, drop-ins and their enables
#   3. в42 changes not yet in the stage: GPS pause in the sleep, dark resume for mobile data, NFC switch (no Plasma tile)
#   4. the Lomiri fixes found on 002 (002/extra-files) minus the Plasma/Lomiri switch
# Kernel modules are NOT taken from here: they are installed fresh from the kernel tree (v241) by the caller.
set -eu
B=$(cd "$(dirname "$0")" && pwd)
M=/home/sasha/Templates/майнлайн
STAGE=$M/архив/.v42-zip-stage/mainline-extras/rootfs-files
V42=$M/архив/в42
L=$B/layer
rm -rf "$L"
mkdir -p "$L"

# 1. stage rootfs-files without Plasma/KDE (and without modules and the system-partition fstab)
(cd "$STAGE" && tar -cf - \
	--exclude='usr/lib/qt6' --exclude='usr/share/plasma' --exclude='usr/share/locale' \
	--exclude='usr/share/sounds/ocean' --exclude='usr/share/kdevappwizard' --exclude='usr/share/knotifications6' \
	--exclude='usr/share/qlogging-categories6' --exclude='usr/include' \
	--exclude='usr/lib/libKirigami*' --exclude='usr/lib/libktelephonymetatypes.a' --exclude='usr/lib/libplasmanm_cellular.so' \
	--exclude='usr/lib/libQt6*' \
	--exclude='usr/bin/plasma-*' --exclude='usr/bin/kalk' \
	--exclude='usr/lib/libexec/kde-telephony-daemon' --exclude='usr/lib/libexec/modem-daemon' --exclude='usr/lib/libexec/spacebar-daemon' \
	--exclude='usr/share/applications/kcm_plasmakeyboard.desktop' --exclude='usr/share/applications/org.kde.*' \
	--exclude='usr/local/share/applications/org.kde.*' --exclude='usr/local/bin/m52xq-plasma-camera' \
	--exclude='usr/share/metainfo/org.kde.*' --exclude='usr/share/icons/hicolor/scalable/apps/org.kde.kalk.svg' \
	--exclude='usr/share/icons/hicolor/scalable/apps/dialer.svg' \
	--exclude='etc/xdg/autostart/org.kde.*' --exclude='usr/share/dbus-1/services/org.kde.*' \
	--exclude='usr/share/dbus-1/interfaces/org.kde.*' \
	--exclude='home/user/.config' --exclude='etc/systemd/system/plasma-mobile.service.d' \
	--exclude='lib/modules' --exclude='usr/lib/modules' --exclude='etc/fstab' \
	--exclude='lib/firmware/imx616-qsc.bin' \
	.) | tar -C "$L" -xf -

# 2. the phone layer (owners kept); etc/systemd/system: only ours
P=$B/phone-layer
(cd "$P" && tar -cf - --exclude='etc/systemd/system' --exclude='etc/systemd/user' --exclude='etc/polkit-1/rules.d' \
	--exclude='usr/lib/firmware/imx616-qsc.bin' .) | tar -C "$L" -xpf -
mkdir -p "$L/etc/systemd/system" "$L/etc/systemd/user" "$L/etc/polkit-1/rules.d"
(cd "$P/etc/systemd/system" && find . -maxdepth 1 \( -name 'm52xq-*' -o -name '*.service.d' \) ! -name 'plasma-mobile.service.d' \
	! -name 'm52xq-bootreport.service' | tar -cf - -T -) | tar -C "$L/etc/systemd/system" -xpf -
(cd "$P/etc/systemd/system" && find . -mindepth 2 -maxdepth 2 -type l -path './*.wants/*' |
	grep -E '/(m52xq-[^/]*|rmtfs\.service|tqftpserv\.service|hexagonrpcd-[^/]*|unudhcpd@usb0\.service)$' |
	grep -v 'm52xq-bootreport' | tar -cf - -T -) | tar -C "$L/etc/systemd/system" -xpf -
(cd "$P/etc/systemd/user" && find . \( -name 'm52xq-*' \) | tar -cf - -T -) | tar -C "$L/etc/systemd/user" -xpf -
cp -a "$P"/etc/polkit-1/rules.d/50-m52xq-*.rules "$L/etc/polkit-1/rules.d/"

# 3. в42 changes not yet in the stage (GPS pause, dark resume for mobile data, NFC switch without the Plasma tile)
cp -a "$V42/gps-sleep/." "$L/"
cp -a "$V42/dark-resume-data/." "$L/"
(cd "$V42/nfc-ui" && tar -cf - --exclude='usr/share/plasma' --exclude='usr/lib/qt6' .) | tar -C "$L" -xf -

# 4. Lomiri fixes from 002 without the Plasma/Lomiri switch (tinydm starts Lomiri in a real install)
(cd "$M/убунтутач24/002/extra-files" && tar -cf - \
	--exclude='usr/local/bin/m52xq-ui-switch-menu' --exclude='usr/local/share/m52xq/ui-switch-menu.qml' \
	--exclude='usr/share/applications/m52xq-ui-switch.desktop' --exclude='etc/systemd/system/m52xq-ui-switch@.service' \
	--exclude='etc/polkit-1/rules.d/50-m52xq-ui-switch.rules' --exclude='usr/lib/systemd/system/m52xq-lomiri.service' \
	.) | tar -C "$L" -xf -

# Plasma leftovers that came with the phone's /usr/local
rm -f "$L/usr/local/bin/m52xq-plasma-camera" "$L"/usr/local/share/applications/org.kde.*.desktop

# 5. what only this image needs: the tinydm session with our Lomiri environment, own fstab (home not shared with
# Plasma), portrait as the default orientation
cp -a "$B/extra-003/." "$L/"

# our programs and configs belong to root, whatever the build host user was
chown -R 0:0 "$L/usr" "$L/etc" "$L/lib" 2>/dev/null || true
# the phone layer has the right owners for the sensor registry (fastrpc 108:113) and NM connections (root, 600)
[ -d "$P/usr/share/qcom" ] && (cd "$P" && tar -cf - usr/share/qcom) | tar -C "$L" -xpf -
find "$L" -type f | wc -l
