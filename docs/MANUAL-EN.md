# postmarketOS + Lomiri on a mainline kernel for the Samsung Galaxy M52 5G (m52xq) — full manual

Document version: 2026-11-10. Release: **unofficial v1** (2026-11-10), archive `postmarketos-lomiri-m52xq-mainline-v1-UNOFFICIAL.zip`.
What changed after the archive v5: [CHANGES-v1.md](CHANGES-v1.md).

## 1. What this is

- Device: Samsung Galaxy M52 5G, SM-M526B / SM-M526BR, Snapdragon 778G (SM7325, platform "yupik"), codename `m52xq`.
- Kernel: **mainline Linux 7.1.13** with device patches — the same kernel as the Ubuntu Lomiri port (classic), no Halium, no libhybris.
  All drivers are native Linux drivers (DRM/KMS, ALSA, QMI modem).
- System: **postmarketOS edge** (Alpine, systemd) with the **Lomiri 0.6.2** shell (Ubuntu Touch), **without Plasma**. Base package list: `docs/packages-003.txt`.
- Phone hardware support (firmware handling, `m52xq-*` services) is shared with the Plasma port, repository
  [samsung-m52xq-mainline](https://github.com/korryasdlerto-lgtm/samsung-m52xq-mainline). This repository holds what was done for Lomiri on top of it.
- Unofficial port: not a postmarketOS or UBports release. Personal hobby project, tested on one SM-M526B.
- Wiki page: [User:Asdlerto Korry](https://wiki.nura.eco/wiki/User:Asdlerto_Korry)

Videos:
- installation: https://www.youtube.com/watch?v=7mkKoSjPERk
- going back to Android: https://www.youtube.com/watch?v=0lgLbtdl4rA

## 2. What works

| Feature | State | Notes |
|---|---|---|
| Boot, Lomiri shell | works | boots from UFS, 8 GB system partition; tinydm session `m52xq-lomiri.desktop` → `m52xq-start-lomiri`; "postmarketOS / Lomiri" splash |
| First-run wizard | works | language, Wi-Fi, time zone (the chosen time zone is applied: polkit rule for systemd-timedated) |
| Display, GPU, touch | works | Mir on gbm-kms + Mesa freedreno (Adreno 642L); S6E3HAB panel, brightness, auto-rotation; Synaptics; fast taps on the dial pad are not lost |
| On-screen keyboard | works | maliit (Qt6), bridge `m52xq-osk-bridge` for text-input-v3 apps (Firefox) |
| Calls | works | plasma-dialer on 2 SIMs adapted to Lomiri: call window on the lock screen, call bar with call time and name, loudspeaker/earpiece switch during a call |
| Calls in sleep | works | the screen turns on for a modem call; after the call the lock screen comes back (no stuck dialer) |
| SMS | works | Spacebar on several modems; unread messages in the Lomiri messaging indicator (`m52xq-messaging-bridge`) |
| Two SIMs, mobile data | works | ModemManager with DSDS patches; SIM manager: SIM power, mode (dual / SIM1 only / SIM2 only), data SIM and data switch, in sync with the quick settings |
| Contacts | works | names in the dialer and the call log |
| Wi-Fi, Bluetooth | works | WCN6750; Wi-Fi stays connected in sleep and wakes the phone for incoming traffic (WoWLAN + APF); Bluetooth audio |
| Telegram Desktop | works | messages and calls arrive in sleep, the screen turns on for a call, call audio in the earpiece |
| Audio | works | loudspeaker, earpiece, microphones, in-call noise suppression |
| Camera | works | `lomiri-camera-app` with our own GStreamer source: rear and front, digital zoom up to 4x, video with the Venus hardware encoder; Megapixels adapted to Lomiri |
| GPS | works | ModemManager GNSS → gpsd → lomiri-location-service; XTRA assistance data for a fast fix; Pure Maps |
| Sensors | works | light, proximity (screen off at the ear), accelerometer |
| Battery, charging | works | battery level, Samsung AFC 9 V fast charging |
| Suspend | works | about 1 % per hour overnight with Wi-Fi connected; wakes for calls, SMS, alarms; the screen stays dark on network wake-ups |
| Alarm | works | wakes the phone from sleep (RTC) |
| Swap | works | zram (zstd) |
| Fingerprint, VoLTE | no | calls use 2G/3G |

Known issues of v1:
- rarely the Wi-Fi firmware crashes during a long sleep and Wi-Fi stays off — a reboot brings it back;
- after switching networks the Wi-Fi icon in the top bar can disappear although Wi-Fi is connected — a reboot fixes it;
- a "System Settings → Time & Date" window that was open before the time zone changed keeps showing the old time — close and reopen it;
- not every camera lens and mode is supported; image processing is done in software;
- `apk upgrade` replaces the patched packages of the port (ModemManager, plasma-dialer, Kirigami and others) with edge packages — do not run a full upgrade.

## 3. Requirements

- SM-M526B with an **unlocked bootloader**;
- TWRP for m52xq: https://github.com/saadelasfur/Action-Recovery-Builder/releases/tag/20261004173308 ;
- a microSD card with the zips (Format Data erases the internal storage);
- a PC with Odin and the stock firmware for your model and region, in case you want to go back.

**Backups first.** From TWRP back up at least EFS, persist, modem, boot, vendor_boot, vbmeta and copy them to your PC.

**Device firmware is taken from your own phone.** The zip contains no proprietary firmware: the installer copies the DSP, GPU,
IPA (mobile data), video codec, Bluetooth and modem firmware and the sensor configs from the phone's own `apnhlos`, `vendor`,
`modem`, `persist` and `EFS` partitions (read-only). So these partitions must be intact, and `vendor` must come from a
Samsung-based ROM (stock, UN1CA or LineageOS). The phone also gets its own Bluetooth address, SSH keys and machine ID during the
install and the first boot.

## 4. Installation with TWRP

Archive: `postmarketos-lomiri-m52xq-mainline-v1-UNOFFICIAL.zip`, 1 411 797 780 bytes (1.3 GB), md5 `eba0bbd593c733a6f49ccc6ab4d63ac2`.
Download: https://drive.google.com/file/d/1oQfJQ7r_41BDXRptXBHdAxwSDonf08J7/view?usp=sharing
(the archive is not in the repository: it contains a built system image; section 8 shows how it is built).

**Warning:** the phone gets warm during the install. If your display already shows vertical coloured lines, do not install this:
the heat may make them worse.

System partition size: the installer grows the system partition to 8 000 000 000 bytes, and the system then fills it entirely.
Flash **UN1CA_3.1.0** first to get the maximum partition size; after LineageOS 23 the partition is 1 GB smaller, but the install still succeeds.

TWRP steps (as in the video):
```
Wipe - Format Data - yes - enter - Back - Back - Advanced Wipe - Data - Repair or Change File System - Change File System - EXT4 -
Swipe to Change - Back - Back - Back - Back - Back - Install - Select Storage - Micro SD card -
postmarketos-lomiri-m52xq-mainline-v1-UNOFFICIAL.zip - Swipe to confirm Flash - Reboot System
```
- Coming from v5 or an older archive, do the same clean install (Format Data).
- The install takes about 2 minutes; it must end with `Updater process ended with RC=0`.
- "Failed to mount '/system_root'" at the very end is normal for a pmOS image (TWRP expects Android).
- The first boot takes longer; then the setup wizard starts: language, Wi-Fi, time zone.
- If `/data` has a `rootfs.img` in its root, the boot loader prefers it — remove or rename it before installing.

What the installer does (`installer/META-INF/com/google/android/update-binary`):
1. writes `firmware/boot_v256_k7.1.13_panel-sleep.img` to `boot`, after adding the IPA firmware from the phone's `apnhlos`
   partition to its ramdisk (IPA is built into the kernel and starts before the root is mounted);
2. writes `firmware/vendor_boot_m52xq-local-v35-rtc.img` to `vendor_boot` and `firmware/dtbo-frag-m52xq.img` to `dtbo`;
3. grows the `system` partition (dynamic partition in super) to 8 000 000 000 bytes;
4. joins the chunks `data/rootfs-chunks/samsung-m52xq.img.part-*` and writes the image to `/dev/block/mapper/system`
   (GPT, 4096-byte sectors, p1 `pmOS_boot`, p2 root — the first boot grows p2 to the whole partition);
5. puts the files of `mainline-extras/rootfs-files` over the root (in v1: the polkit time zone rule and the marker
   `/etc/m52xq/lomiri-release`), compiles GSettings;
6. takes from the phone (read-only): the Bluetooth address from EFS; the ADSP, GPU, IPA, Venus firmware from `apnhlos`; the
   Bluetooth firmware and sensor configs from `vendor`; the modem firmware from `modem`; the sensor registry from `persist`.

The installer does not touch `userdata`.

**Default password** (4-digit screen unlock, user `user` and root): **1111**.
Change it in "System Settings → Security & Privacy" or in a terminal: `printf "user:NEW\n" | sudo chpasswd`.

SSH over USB (about 30 s after boot): `ssh user@172.16.42.1`, password 1111 (USB networking is set up by `m52xq-usbnet`).

Screenshot: press **Volume Up + Volume Down** together; the file goes to `~/Pictures/Screenshots`.

## 5. Going back to Android

Video: https://www.youtube.com/watch?v=0lgLbtdl4rA

Works for going back to LineageOS or UN1CA; stock is better restored with Odin or Heimdall. If the port you are leaving has no
reboot-to-recovery option, enter recovery with the usual power and volume key combination. Copy the firmware zip to the microSD first.
```
Wipe - Format Data - yes - enter - Back - Back - Back - Advanced Wipe - Data - Repair or Change File System - Change File System - EXT4 -
Swipe to Change - Back - Back - Back - Back - Back - Install - lineage-23.2-2026-nightly-m52xq-signed.zip - Back - Back - Wipe -
Format Data - enter - Reboot System
```
Latest LineageOS build: https://download.lineageos.org/devices/m52xq/builds .
Stock firmware can always be restored with Odin (BL, AP, CP, CSC).

## 6. Kernel

Details: [kernel/README.md](../kernel/README.md): `kernel/config-7.1.13` and the changes in `kernel/patches/*.diff`
(call device switch without new q6voice sessions, panel sleep while the brightness is 0, ath11k power save with the radio off).

Binaries (`boot.img`, `vendor_boot.img`, `dtbo-frag.img`, `Image`, `modules-7.1.13.tar.gz`, `SHA256SUMS`): release
[kernel-7.1.13](https://github.com/korryasdlerto-lgtm/samsung-m52xq-ubuntu-lomiri/releases/tag/kernel-7.1.13) of
samsung-m52xq-ubuntu-lomiri. The images in `firmware/` of the v1 zip are byte-identical to `boot.img`, `vendor_boot.img`,
`dtbo-frag.img` of that release (sha256 `2b5962c1…`, `53965b55…`, `c9114568…`).

The device tree is upstream-style with local nodes; RTC is enabled (alarm from sleep). Almost all drivers are built in; only
Wi-Fi AHB, v4l2loopback and Venus are modules. `MODVERSIONS` is off — install the modules only together with this boot image.

Flashing the kernel alone (phone in TWRP, files in `/data`):
```sh
adb push boot.img vendor_boot.img dtbo-frag.img /data/
adb shell 'dd if=/data/boot.img of=/dev/block/by-name/boot bs=4M && dd if=/data/vendor_boot.img of=/dev/block/by-name/vendor_boot bs=4M && dd if=/data/dtbo-frag.img of=/dev/block/by-name/dtbo bs=4M && sync'
adb shell 'md5sum /dev/block/by-name/boot | head -c 32; echo'      # to compare, read as many bytes as the file has
```
Without the installer the IPA firmware is not added to boot and mobile data will not work — flash the kernel alone only if you know that.

Kernel source: [sc7280-mainline-linux-m52xq](https://github.com/korryasdlerto-lgtm/sc7280-mainline-linux-m52xq).
Old kernel of the archives v2–v5: `kernel/config-7.1.2-430` and release kernel-7.1.2-430 of this repository.

## 7. Repository layout

| Folder | Contents |
|---|---|
| `installer/META-INF` | TWRP installer (`update-binary`, `updater-script`) of release v1 |
| `rootfs-overlay/` | all files put over the image in versions 2 – v1 (scripts, services, sleep hooks, QML, configs); binaries listed in `rootfs-overlay/EXCLUDED-FILES.txt` (path, size, md5) |
| `image/` | root build: `build-layer.sh`, package lists, repositories, device package `device-pkg`, session `extra-003`, splash `splash`; `build-v6/v7/v8-image.sh` — release image snapshot |
| `build/v2…v7/` | sources and patches of every rebuilt program, per version (section 9) |
| `kernel/` | kernel configs and changes |
| `docs/` | this manual (EN/RU, Markdown and Word), CHANGES-v1, work log `ЖУРНАЛ-УБУНТУТАЧ24.md`, all commands `КОМАНДЫ-УБУНТУТАЧ24.md`, "what's new" v5–v9, to-do lists |

Personal data of the test phone (Bluetooth address, sensor registry, Wi-Fi networks, SIM data, keys, coordinates) is not in the repository.

## 8. Building

The exact commands run for every version (with output and md5) are in `docs/КОМАНДЫ-УБУНТУТАЧ24.md` and
`docs/ЖУРНАЛ-УБУНТУТАЧ24.md`; what changed in every version — `docs/ЧТО_НОВОГО-v5.txt` … `-v9.txt` (Russian).

Host: Ubuntu 20.04 x86_64, `qemu-user-static` + binfmt (flag F), pmbootstrap (for `apk.static` and the keys), about 20 GB of space.

The v1 image was made in two stages: the base root (8.1–8.3, archives v2–v5); then the fixes of v6–v8 were installed and tested
on the phone, and a clean snapshot was taken from the configured phone (8.4).

### 8.1. postmarketOS edge + Lomiri root
pmbootstrap's pmaports is on branch v26.06 and `postmarketos-ui-lomiri` exists only in edge, so the root is installed with
`apk.static` directly, using the phone's repositories (`image/repositories`) and a separate cache:
```sh
R=$PWD/rootfs; mkdir -p $R/etc/apk; cp image/repositories $R/etc/apk/repositories
sudo cp -a ~/.local/var/pmbootstrap/config_apk_keys $R/etc/apk/keys
sudo ~/.local/var/pmbootstrap/apk.static --arch aarch64 --root $R --initdb --cache-dir $PWD/apk-cache \
     --allow-untrusted add $(grep -v '^#' image/world-003.txt)
```
Contents (`world-003.txt`): the phone's base (`postmarketos-base`, `-systemd`, `postmarketos-mkinitfs`, sudo-rs),
`postmarketos-ui-lomiri`, `lomiri-ui-extras-qt5`, `maliit-keyboard`, ayatana indicators, ModemManager, rmtfs, tqftpserv, hexagonrpcd,
qrtr, libssc, iio-sensor-proxy, `postmarketos-usb-moded`, Megapixels, Firefox, Organic Maps, Lomiri apps.
Packages added on the phone later: `image/phone-world.txt`.

### 8.2. m52xq hardware layer
`image/build-layer.sh` applies, in order:
1. the Plasma port overlay (`samsung-m52xq-mainline/rootfs-overlay`) without Plasma/KDE;
2. a layer read from the phone (firmware, `/etc/m52xq`, sensor registry, `/usr/local`, udev, NM/ssh/polkit, `m52xq-*` units) —
   **not in the repository**: it is personal data and proprietary firmware of the phone; the installer takes it from your phone itself;
3. Lomiri fixes: LightDM.IntegratedLightDM and SystemSettings.Update stubs, `lomiri-bin` wrappers, maliit on wayland, deviceinfo (GridUnit 21);
4. `image/extra-003`: tinydm session, own `fstab` (logs, coredumps, apk cache on userdata; home in the image), portrait by default;
5. the kernel modules and the device package `image/device-pkg`.

Differences of current edge handled by hand: `/lib` and `/sbin` are real directories (firmware in `/lib/firmware`, links from
`/usr/lib/firmware`); `fastrpc` = 103:105 (the installer re-owns the sensor registry); user `user` 10000:10000, groups wheel audio
input video netdev plugdev feedbackd; directory permissions restored from the apk database; `hexagonrpcd-sdsp` and `routewrangler` disabled.

### 8.3. Changes of versions 2 – v1
Put `rootfs-overlay/` over the root (owner root, modes as in the overlay) and build the binaries from `build/` (section 9):
```sh
sudo cp -a --no-preserve=ownership rootfs-overlay/. $R/
sudo rm $R/EXCLUDED-FILES.txt
sudo chroot $R glib-compile-schemas /usr/share/glib-2.0/schemas
```
Binaries and modules are listed in `rootfs-overlay/EXCLUDED-FILES.txt` with md5, so you can check your own build.

### 8.4. Release image (snapshot of a configured phone)
`image/build-v8-image.sh` copies the root from the phone over USB (GNU tar 1.35 with xattrs and file capabilities; busybox tar loses
them; sleep is blocked with `systemd-inhibit` during the copy) into a fresh ext4, keeping the layout, `pmOS_boot` and the clean
`/home` of the base image:
```sh
OLD=base-v3.img NEW=samsung-m52xq-lomiri-v1-release.img PATTERNS=personal-values.txt ./image/build-v8-image.sh
```
Excluded: `/home`, logs, caches, coredumps, Wi-Fi networks (`<HOME-WIFI>*` — put the names of your own profiles there), Bluetooth
pairings, SIM choices (`etc/m52xq/{bt_addr,data-sim,sim-mode,sms-sim}`), `etc/ssh/ssh_host_*` keys, machine ID (left empty),
proprietary firmware (`lib/firmware/{adsp*,modem*,a660_zap*,yupik_ipa_fws*,qca/*,qcom/vpu-2.0/*}`) and the sensor configs/registry.
The `root` and `user` passwords are set to 1111. At the end the script searches the image for personal values (Bluetooth address
and MAC, IMEI, IMSI, ICCID, phone numbers, password hashes, the lines of `PATTERNS`) and fails if it finds any.

### 8.5. Archive
The v1 image chunks are those of the flashed and tested archive; the kernel comes from release kernel-7.1.13 under the names the
installer expects. `mainline-extras` must hold at least one file: the block that copies firmware from the phone is nested inside
the check for `mainline-extras/rootfs-files`.
```sh
mkdir -p archive/data/rootfs-chunks archive/firmware archive/mainline-extras/rootfs-files/etc/m52xq archive/mainline-extras/rootfs-files/etc/polkit-1/rules.d
split -b 2479603712 -d -a 1 samsung-m52xq-lomiri-v1-release.img archive/data/rootfs-chunks/samsung-m52xq.img.part-
cp -a installer/META-INF archive/
cp boot.img        archive/firmware/boot_v256_k7.1.13_panel-sleep.img
cp vendor_boot.img archive/firmware/vendor_boot_m52xq-local-v35-rtc.img
cp dtbo-frag.img   archive/firmware/dtbo-frag-m52xq.img
cp rootfs-overlay/etc/polkit-1/rules.d/50-m52xq-timedate.rules archive/mainline-extras/rootfs-files/etc/polkit-1/rules.d/
echo "postmarketos-lomiri v1" > archive/mainline-extras/rootfs-files/etc/m52xq/lomiri-release
find archive -xtype l                                     # there must be no broken links
cd archive && zip -9 -r ../postmarketos-lomiri-m52xq-mainline-v1-UNOFFICIAL.zip . && cd ..   # from inside the folder, no prefix
unzip -t postmarketos-lomiri-m52xq-mainline-v1-UNOFFICIAL.zip | tail -1
```
Files that are already in the image are not put into `mainline-extras` again.

## 9. Rebuilt programs (`build/`)

| Folder | What changed |
|---|---|
| `v2/maliit-qt6` | maliit-framework for Qt6 (CMake from master and PR 125) |
| `v3/integratedlightdm` | LightDM stub for Lomiri without lightdm (patches 0001–0006, APKBUILD) |
| `v3/lomiri-app-launch` | `0002-m52xq-posix-reap-children-per-app-pids-stop` — stopping app processes |
| `v3/lomiri-launcher`, `v3/lomiri-shell` | launcher index at press time; two wallpapers (desktop / lock screen) |
| `v3/lomiri-system-settings` | "About phone" for mainline (IMEI from ModemManager, OS, apk licences), brightness, ru translation |
| `v3/lomiri-camera-app`, `v5/lomiri-camera-app` | QZXing optional, 4K video, 16 MP with binning |
| `v3/m52xqcamsrc`, `v5/…`, `v6/…`, `v7/m52xqcamsrc` | own GStreamer camera source: Venus hardware encoding, autofocus, digital zoom up to 4x (v7) |
| `v3/libcamera` | APKBUILD + soft-ISP patches (tetracell S5KGW3 remosaic, no sensor writes without AGC) |
| `v3/plasma-dialer`, `v4/dialer-*`, `v4/incoming-call`, `v6/plasma-dialer` | 2 SIMs, call over the lock screen, "add contact", SIM in the call log, Lomiri call decision, call bar |
| `v4/spacebar-multimodem` | SMS on several modems |
| `v4/calls-lockedapp` | Shell.qml: dialer over the lock screen; in v1 — the lock screen comes back after a call in sleep |
| `v3/powerkey` | `m52xq-powerkey` v2: idle, "keep screen on", sleep |
| `v3/qmlkonsole` | key bar above the on-screen keyboard |
| `v3/aa-shim`, `v3/cellular`, `v3/indicator-bluetooth` | AppArmor stub for click, cellular settings module, Bluetooth indicator |
| `v3/translations` | Russian translations of settings and the power indicator |
| `v5/ath11k-ahb` | `ahb.c` with a retry on resume (WoWLAN; in v1 the ath11k change is in the kernel) |
| `v6/modemmanager` | fixed a crash on data connect (use-after-free) |
| `v6/kpeople`, `v6/qtorganizer5-eds` | KPeople crash (database used from two threads); calendar/alarm |
| `v6/megapixels`, `v7/…` | Megapixels for Lomiri (scale, buttons in portrait and landscape) |
| `v7/kirigami` | ColumnView no longer starts an empty animation on every tap (patch for 6.31) — fast dialing |
| `v7/gps` | `m52xq-gps-alt` shim (LD_PRELOAD) for lomiri-location-service with gpsd ≥ 3.20; XTRA |
| `v7/sim` | SIM manager: mobile data switch, sync with the quick settings |

Builds run in a pmbootstrap chroot (aarch64, `--arch aarch64`) or an Alpine chroot; the exact commands are in
`docs/КОМАНДЫ-УБУНТУТАЧ24.md` and `docs/ЖУРНАЛ-УБУНТУТАЧ24.md`.

## 10. Services and scripts of the Lomiri layer

| Service / script | Purpose |
|---|---|
| `m52xq-start-lomiri` | starts the Lomiri session (PATH with lomiri-bin, QML2_IMPORT_PATH, GRID_UNIT_PX=21) |
| `m52xq-powerkey` (+ .service) | short power press: lock and screen off / screen on, sleep |
| `m52xq-osk-bridge` | on-screen keyboard for text-input-v3 (Firefox): input_method_v2 ↔ maliit-server |
| `m52xq-ringtone` | ringtone and vibration for incoming modem calls |
| `m52xq-incall-proximity` | screen off at the ear during a call |
| `m52xq-audio-route`, `m52xq-voip-audio` | call audio route; Telegram call audio in the earpiece |
| `m52xq-messaging-bridge` | unread SMS in the Lomiri messaging indicator |
| `m52xq-sim-slots`, `m52xq-sim-mode-menu` | slot number of each SIM (ICCID), SIM manager: power, mode, data SIM, data switch |
| `m52xq-gnss-gpsd`, `m52xq-gps-xtra` (+ .timer), `m52xq-gps-restore` | ModemManager GNSS (NMEA in order) → gpsd; XTRA data loaded into the modem after boot |
| `m52xq-wow-params`, sleep hooks `m52xq-wifi-sleep`, `m52xq-nm-keep-wifi`, `m52xq-wifi-dark` | WoWLAN/APF, Wi-Fi connected in sleep, no screen flash on network wake-ups |
| `m52xq-spacebar-sleep`, `m52xq-quiet-sleep`, `m52xq-timesyncd.sh` | SMS in sleep, quiet sleep, time sync after sleep |
| `m52xq-audio-reprobe`, `m52xq-audio-rescue`, `m52xq-tfa-guard` | re-probe of the LPASS VA macro after the ADSP start race, audio recovery, TFA amplifier |
| `m52xq-venus-load`, `m52xq-virtualcam`, `m52xq-camera-postprocess` | Venus module loading, virtual camera, photo processing |
| `m52xq-megapixels-lomiri` | starts Megapixels under Lomiri |
| `m52xq-reboot-recovery` | power menu: reboot to recovery |
| `m52xq-app-env` | app launch environment (scale, Qt variables) |
| `m52xq-zram` | zram swap |
| `etc/polkit-1/rules.d/50-m52xq-timedate.rules` | time zone change from the wizard and settings without the admin password |

Shared hardware services (modem, audio, sensors, Wi-Fi, sleep, NFC) are in the Plasma port repository.

## 11. Traps

- Lomiri telephony (`lomiri-telephony-service`) needs telepathy-ofono; our modem goes through ModemManager, so calls and SMS use plasma-dialer and Spacebar.
- `iio-sensor-proxy` rotated app windows and touches landed in the wrong place; the default orientation is portrait.
- Do not install dev packages that downgrade systemd/libc on the phone; `apk upgrade` replaces our builds. Check what `apk add` wants to remove first.
- The Lomiri network indicator runs in the session scope (it has no unit): restart it with `systemd-run --user`, not `setsid` from ssh.
- `pkill -f` inside an ssh command kills its own session — stop processes by PID.
- Build the zip only from inside the archive folder (`cd archive && zip -9 -r ../x.zip .`), otherwise TWRP does not find `META-INF`.
- `losetup` of the image needs `--sector-size 4096`, otherwise p1/p2 are not visible.
- Snapshot from the phone only with GNU tar: busybox tar has no `--null`/`-T` and keeps no xattrs.

## 12. Credits
postmarketOS and pmbootstrap; UBports and Lomiri; Alpine Linux; KDE (plasma-dialer, Spacebar, Kirigami); the mainline Linux
developers for Qualcomm SC7280/QCM6490 (Fairphone 5 and others).
