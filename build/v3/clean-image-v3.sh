#!/bin/bash
# Очистка копии образа lomiri v3 от личных данных (запускать на компьютере, не на телефоне).
# Работает ТОЛЬКО в смонтированной копии 003/rootfs-v3.img (/tmp/rv3), телефона не касается. Нужен sudo.
set -eu
R=/tmp/rv3
[ -d "$R/etc" ] && [ -d "$R/home/user" ] && grep -q "$R" /proc/mounts || { echo "образ не смонтирован в $R"; exit 1; }

echo "== личные файлы пользователя (снимки экрана, фото, видео, документы)"
for d in Pictures Videos Documents Downloads Music; do
	sudo find "$R/home/user/$d" -mindepth 1 -delete
done

echo "== данные приложений и браузеров, учётные записи, ключи"
for p in .cache .pki .presage .ash_history; do sudo rm -rf "$R/home/user/$p"; done
for p in TelegramDesktop keyrings evolution morph-browser OMaps weather.ubports calculator.ubports clock.ubports \
	gallery.ubports plasma-dialer spacebar kpeople kpeoplevcard telepathy; do
	sudo rm -rf "$R/home/user/.local/share/$p"
done
for p in mozilla morph-browser OMaps goa-1.0 libaccounts-glib evolution pure-maps weather.ubports clock.ubports \
	gallery.ubports filemanager.ubports camera.ubports terminal.ubports connectivity-service osmscout-server \
	"Unknown Organization"; do
	sudo rm -rf "$R/home/user/.config/$p"
done
sudo find "$R/home/user/.local/state" -mindepth 1 -delete
sudo find "$R/home/user/.cache" -mindepth 1 -delete 2>/dev/null || true

echo "== сети, Bluetooth, идентификаторы телефона"
sudo rm -f "$R"/etc/NetworkManager/system-connections/<Wi-Fi>*.nmconnection
sudo find "$R/var/lib/bluetooth" -mindepth 1 -delete
sudo find "$R/var/lib/NetworkManager" -mindepth 1 -delete
for f in etc/m52xq/bt_addr etc/m52xq/data-sim etc/m52xq/sim-mode etc/m52xq/flight etc/machine-id var/lib/dbus/machine-id \
	etc/shadow.m52xq.bak etc/fstab.m52xq.bak var/lib/systemd/random-seed; do
	sudo rm -f "$R/$f"
done
sudo rm -f "$R"/etc/ssh/ssh_host_*
echo "== прошивка модема и реестр датчиков (личное, ставятся установщиком с телефона)"
sudo rm -rf "$R"/lib/firmware/modem.* "$R/lib/firmware/modemr.jsn" "$R/lib/firmware/modem_pr"
sudo rm -rf "$R/usr/share/qcom/sm7325/Samsung/m52xq/sensors/registry"
echo "== журналы и /root"
sudo find "$R/var/log" -mindepth 1 -delete
sudo find "$R/root" -mindepth 1 -delete

echo "== мои резервные копии"
for f in usr/share/glib-2.0/schemas/99-m52xq-lomiri.gschema.override.pre-v3 usr/share/lomiri/Shell.qml.v2 \
	usr/local/share/applications/me.gapixels.Megapixels.desktop.pre-v3 usr/local/sbin/m52xq-powerkey.v1 \
	usr/lib/liblomiri-app-launch.so.0.0.0.orig \
	usr/lib/lomiri-system-settings/private/Lomiri/SystemSettings/Brightness/libLomiriBrightnessPanel.so.orig \
	usr/lib/lomiri-system-settings/private/Lomiri/SystemSettings/StorageAbout/libLomiriStorageAboutPanel.so.orig \
	usr/share/lomiri-system-settings/qml-plugins/about/Software.qml.orig \
	usr/share/lomiri-system-settings/qml-plugins/about/PageComponent.qml.orig \
	usr/share/locale/ru/LC_MESSAGES/lomiri-system-settings.mo.orig usr/share/lomiri/Launcher/LauncherPanel.qml.orig \
	usr/bin/qmlkonsole.orig usr/bin/plasma-dialer.orig; do
	sudo rm -f "$R/$f"
done
echo "готово; пароль user (1111) и маркер etc/.m52xq-default-password-set оставлены по решению пользователя"
