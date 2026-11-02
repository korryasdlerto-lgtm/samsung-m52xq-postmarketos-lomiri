# postmarketOS + Lomiri on a mainline kernel for the Samsung Galaxy M52 5G (m52xq) — full manual

Document version: 2026-11-02. Latest archive: **lomiri v5** (2026-10-30).

## 1. What this is

- Device: Samsung Galaxy M52 5G, SM-M526B / SM-M526BR, Snapdragon 778G (SM7325, platform "yupik"), codename `m52xq`.
- Kernel: **mainline Linux 7.1.2**, build **#430** (boot v241 + vendor_boot v238) — the same kernel as the Plasma port, no Halium, no libhybris.
- System: **postmarketOS edge** (Alpine) with the **Lomiri 0.6.2** shell (Ubuntu Touch), **without Plasma**. 1102 packages (`docs/packages-003.txt`).
- Phone hardware support (kernel, firmware handling, `m52xq-*` services) is shared with the Plasma port, repository
  [samsung-m52xq-mainline](https://github.com/korryasdlerto-lgtm/samsung-m52xq-mainline). This repository holds what was done for Lomiri on top of it.
- Personal hobby port, tested on one SM-M526B.

Videos:
- installation: https://www.youtube.com/watch?v=7mkKoSjPERk
- going back to Android: https://www.youtube.com/watch?v=0lgLbtdl4rA

## 2. What works

| Feature | Status | Notes |
|---|---|---|
| Boot, Lomiri shell | works | tinydm session `m52xq-lomiri.desktop` → `/usr/local/bin/m52xq-start-lomiri`; "postmarketOS / Lomiri" boot splash |
| Display, GPU, touch | works | Mir via gbm-kms and Mesa freedreno; S6E3HAB panel; Synaptics TCM |
| On-screen keyboard | works | maliit (Qt6), `m52xq-osk-bridge` for text-input-v3 applications (Firefox) |
| Calls | works | plasma-dialer on 2 SIMs with Lomiri changes (over the lock screen, ringtone and vibration `m52xq-ringtone`, SIM number in the call log) |
| SMS | works | Spacebar on several modems; unread messages in the Lomiri messaging indicator (`m52xq-messaging-bridge`) |
| Mobile data, two SIMs | works | ModemManager with DSDS patches; SIMs in the indicator shade; SIM mode menu |
| Wi-Fi, Bluetooth | works | Wi-Fi stays up in sleep and wakes the phone on a packet (WoWLAN, own `ath11k_ahb.ko`) |
| Audio | works | loudspeaker, earpiece, microphones; `m52xq-audio-reprobe` retries the VA macro probe |
| Camera | works | `lomiri-camera-app` with patches: video through the Venus hardware encoder 1080p/4K (≤ 24 fps), AAC, tap to focus, 16 MP without the checkerboard |
| GPS | partial | ModemManager GNSS → gpsd → lomiri-location-service (`m52xq-gnss-gpsd`); no fix indoors |
| Suspend | works | short power key press locks and blanks (`m52xq-powerkey`); wakes for calls, SMS, Wi-Fi packets |
| Swap | works | zram 7.4 GB (zstd) |
| Maps | works | Pure Maps (osmscout-server, online profile), Organic Maps |
| Fingerprint | no | |

Known issues in v5:
- the camera keeps Venus busy after recording stops — the media player cannot open 4K while the camera is open;
- 4K on the front camera ≈ 17 fps;
- waking on a packet occasionally fakes a key press and lights up the screen;
- a ping from a host without an ARP cache entry may not wake the phone (the APF filter drops broadcast ARP);
- `apk upgrade` replaces our builds (ModemManager, libcamera, plasma-dialer, …) with edge packages.

## 3. Requirements

- SM-M526B with an **unlocked bootloader**;
- TWRP for m52xq: https://github.com/saadelasfur/Action-Recovery-Builder/releases/tag/20261004173308 ;
- a microSD card (Format Data erases the internal storage);
- a PC with Odin and the stock firmware for your model, to go back if needed.

**Back up first.** From TWRP save at least EFS, persist, modem, boot, vendor_boot and vbmeta, and copy them to a PC.

Firmware comes from your own phone: the installer copies the modem firmware, the Bluetooth address (EFS) and the sensor registry
(persist) from the phone itself (read-only). So `apnhlos`, `vendor`, `modem`, `persist` and `EFS` must be intact, and `vendor` must
come from a Samsung-based ROM (stock, UN1CA or LineageOS).

## 4. Installing with TWRP

Archive: `postmarketos-lomiri-m52xq-mainline-v5.zip`, 1 570 774 902 bytes, md5 `a7b6255ca8080f1251fd8b243fe26ab1`
(not published in the repository: it contains the built system image; build it as described in section 8).

System partition size: the installer grows `system` to 8 000 000 000 bytes. Flashing **UN1CA_3.1.0** first gives the largest
partition; after LineageOS 23 it is 1 GB smaller, and the installation still works.

TWRP steps (as in the video):
```
Wipe - Format Data - yes - enter - Back - Back - Advanced Wipe - Data - Repair or Change File System - Change File System - EXT4 -
Swipe to Change - Back - Back - Back - Back - Back - Install - Select Storage - Micro SD card - UN1CA_3.1.0-a5bf09f2_20260604_m52xq-sign.zip -
Swipe to confirm Flash - Back - Back - Wipe - Format Data - enter - Back - Back - Advanced Wipe - Data - Repair or Change File System -
Change File System - EXT4 - Swipe to Change - Back - Back - Back - Back - Back - Install - postmarketos-lomiri-m52xq-mainline-v5.zip -
Swipe to confirm Flash - Reboot System
```
- The installation takes about 2 minutes and must end with `Updater process ended with RC=0`.
- "Failed to mount /system_root" at the end is normal for a pmOS image (TWRP expects Android).
- If `/data` contains a `rootfs.img`, the boot loader prefers it — remove or rename it first.

What the installer does (`installer/META-INF/com/google/android/update-binary`):
1. grows the `system` dynamic partition (super) to 8 000 000 000 bytes;
2. joins the chunks `data/rootfs-chunks/samsung-m52xq.img.part-*` and writes the image to `/dev/block/mapper/system`
   (GPT, 4096-byte sectors, p1 `pmOS_boot`, p2 root — the first boot grows p2 to the whole partition);
3. writes `firmware/boot_v241_nfc.img` to `boot` and `firmware/vendor_boot_v238_nfc_se9.img` to `vendor_boot`;
4. copies `mainline-extras/rootfs-files` over the root (this is `rootfs-overlay/` of this repository), compiles GSettings and
   restores the service links (`*.wants`);
5. takes from the phone: the Bluetooth address from EFS, the modem firmware, the sensor registry from persist (owned by the image's `fastrpc` user).

**Default password** (unlock and root): **112233** — set on first boot by `m52xq-set-default-password`.
Change it in a terminal: `printf "user:NEW\n" | sudo chpasswd`.

USB access: `ssh user@172.16.42.1` (USB networking by `m52xq-usbnet`).

## 5. Going back to Android

Video: https://www.youtube.com/watch?v=0lgLbtdl4rA
```
Wipe - Format Data - yes - enter - Back - Back - Back - Advanced Wipe - Data - Repair or Change File System - Change File System - EXT4 -
Swipe to Change - Back - Back - Back - Back - Back - Install - lineage-23.2-2026-nightly-m52xq-signed.zip - Back - Back - Wipe -
Format Data - enter - Reboot System
```
Stock Samsung firmware can always be restored with Odin (BL, AP, CP, CSC).

## 6. Kernel

Ready files — release [kernel-7.1.2-430](../../releases/tag/kernel-7.1.2-430) of this repository:

| File | What it is |
|---|---|
| `boot_v241_nfc.img` | boot image (kernel #430 + postmarketOS initramfs), md5 `f89bec954c6f3d4933503d260fce83a4` |
| `vendor_boot_v238_nfc_se9.img` | vendor_boot with the phone DTB (NFC, SE9), md5 `e1fb7dd3d01ad972f07887e0295e8fd7` |
| `Image` | the arm64 kernel from boot v241 (no DTB appended — the DTB is in vendor_boot) |
| `config-7.1.2-430` | full `.config` of the build (clang 22 / LLD 22, `make ARCH=arm64 LLVM=1`) |
| `modules-7.1.2-430.tar.gz` | modules, layout `lib/modules/7.1.2/…`: `ath11k_ahb.ko` (v5 variant with resume retries), `extra/v4l2loopback.ko`, `extra/venus/*` |
| `SHA256SUMS` | checksums |

Almost every driver is built in; only Wi-Fi AHB, v4l2loopback and Venus are modules (Venus is loaded by `m52xq-venus-load` with insmod).
`MODVERSIONS` is off — install the modules only together with this boot image.

Flashing the kernel alone (phone in TWRP, files in `/data`):
```sh
adb push boot_v241_nfc.img vendor_boot_v238_nfc_se9.img /data/
adb shell 'dd if=/data/boot_v241_nfc.img of=/dev/block/by-name/boot bs=4M && dd if=/data/vendor_boot_v238_nfc_se9.img of=/dev/block/by-name/vendor_boot bs=4M && sync'
```
Kernel source: [sc7280-mainline-linux-m52xq](https://github.com/korryasdlerto-lgtm/sc7280-mainline-linux-m52xq)
(branch `master` is the newer #437; build #430 differs from it mostly in debug code). The v5 ath11k change:
`build/v5/ath11k-ahb/ahb.c.m52xq-resume` (built in place of `drivers/net/wireless/ath/ath11k/ahb.c`).

## 7. Repository layout

| Folder | Contents |
|---|---|
| `installer/META-INF` | TWRP installer (`update-binary`, `updater-script`), banner "lomiri v5" |
| `rootfs-overlay/` | every file put over the image in versions 2–5 (scripts, services, QML, configs); binaries are listed in `rootfs-overlay/EXCLUDED-FILES.txt` with md5 |
| `image/` | root build: `build-layer.sh`, package list `world-003.txt`, repositories, device package `device-pkg`, session `extra-003`, boot splash `splash` |
| `build/v2…v5/` | sources and patches of every rebuilt program by version (section 9) |
| `docs/` | this manual (RU/EN), the work log `ЖУРНАЛ-УБУНТУТАЧ24.md`, all commands `КОМАНДЫ-УБУНТУТАЧ24.md`, to-do lists by version, "what's new in v5" (Russian) |

## 8. Building from scratch

This is the build outline with the key commands. The exact commands run for every version (with output and md5) are in
`docs/КОМАНДЫ-УБУНТУТАЧ24.md` and `docs/ЖУРНАЛ-УБУНТУТАЧ24.md` (sections "Этап 3" and "Архив lomiri vN").

Host: Ubuntu 20.04 x86_64, `qemu-user-static` + binfmt (F flag), pmbootstrap (for `apk.static` and the keys), about 20 GB free.

### 8.1. postmarketOS edge + Lomiri root
pmbootstrap's pmaports are on v26.06 and `postmarketos-ui-lomiri` exists only in edge, so the root is installed with `apk.static`
directly, with the phone's repositories (`image/repositories`) and a separate cache:
```sh
R=$PWD/rootfs; mkdir -p $R/etc/apk; cp image/repositories $R/etc/apk/repositories
sudo cp -a ~/.local/var/pmbootstrap/config_apk_keys $R/etc/apk/keys
sudo ~/.local/var/pmbootstrap/apk.static --arch aarch64 --root $R --initdb --cache-dir $PWD/apk-cache \
     --allow-untrusted add $(grep -v '^#' image/world-003.txt)
```
Contents (`world-003.txt`, 70 names → 1102 packages): a base like the phone's (`postmarketos-base`, `-systemd`, `postmarketos-mkinitfs`,
sudo-rs), `postmarketos-ui-lomiri`, `lomiri-ui-extras-qt5`, `maliit-keyboard`, ayatana indicators, ModemManager, rmtfs, tqftpserv,
hexagonrpcd, qrtr, libssc, iio-sensor-proxy, `postmarketos-usb-moded`, Megapixels, Firefox, Organic Maps, Lomiri apps.
`telegram-desktop` is not included (edge 7.3.3 needs the missing `libada.so.3`; our ada build — `build/v3/ada3/APKBUILD`).

### 8.2. m52xq hardware layer
`image/build-layer.sh` (reproducible) applies in this order:
1. the Plasma port overlay (`samsung-m52xq-mainline/rootfs-overlay`, v42 state) without Plasma/KDE;
2. a layer read from the phone (firmware, `/etc/m52xq`, sensor registry, `/usr/local`, udev, NM/ssh/polkit, `m52xq-*` units) —
   **not in the repository**, these are the phone's personal data; the installer creates them on your own phone;
3. Lomiri fixes: LightDM.IntegratedLightDM and SystemSettings.Update stubs, `lomiri-bin` wrappers, maliit on wayland, deviceinfo (GridUnit 21);
4. `image/extra-003`: tinydm session, own `fstab` (logs, coredumps, apk cache on userdata; home stays in the image), portrait by default;
5. kernel #430 modules (`modules-7.1.2-430.tar.gz` from the release) and the device package `image/device-pkg`.

Differences of current edge handled by hand: `/lib`, `/sbin` are real directories (firmware in `/lib/firmware`, links from
`/usr/lib/firmware`); `fastrpc` is 103:105 (the installer re-owns the sensor registry); user `user` 10000:10000, groups wheel audio input
video netdev plugdev feedbackd; directory modes restored from the apk database; `hexagonrpcd-sdsp` and `routewrangler` disabled.

### 8.3. Changes of versions 2–5
Copy `rootfs-overlay/` over the root (owned by root, modes as in the overlay):
```sh
sudo cp -a --no-preserve=ownership rootfs-overlay/. $R/
sudo chroot $R glib-compile-schemas /usr/share/glib-2.0/schemas
```
The binaries listed in `EXCLUDED-FILES.txt` are built from `build/` (section 9) or taken from the release (modules).

### 8.4. Image and archive
```sh
# GPT image, 4096-byte sectors: p1 pmOS_boot (from the Plasma archive v35), p2 root (type B921B045, label pmOS_root)
truncate -s 5338300416 samsung-m52xq.img
L=$(sudo losetup -f --show -P --sector-size 4096 samsung-m52xq.img)    # partition the 4096-sector loop device, not the file
sudo sgdisk -o -n1:2048:124927 -c1:pmOS_boot -n2:124928:0 -t2:B921B045-1DF0-41C3-AF44-4C6F280D3FAE -c2:pmOS_root $L
sudo partprobe $L
sudo dd if=pmOS_boot.img of=${L}p1 bs=4M; sudo mkfs.ext4 -L pmOS_root -b 4096 ${L}p2
sudo mount ${L}p2 /mnt && sudo cp -a $R/. /mnt/ && sudo umount /mnt && sudo e2fsck -fy ${L}p2 && sudo losetup -d $L
# archive: chunks + installer + kernel + overlay
mkdir -p archive/data/rootfs-chunks archive/firmware archive/mainline-extras/rootfs-files
split -b 2669150208 -d -a 1 samsung-m52xq.img archive/data/rootfs-chunks/samsung-m52xq.img.part-
cp -a installer/META-INF archive/; cp boot_v241_nfc.img vendor_boot_v238_nfc_se9.img archive/firmware/
cp -a rootfs-overlay/. archive/mainline-extras/rootfs-files/; rm archive/mainline-extras/rootfs-files/EXCLUDED-FILES.txt
find archive -xtype l                                     # there must be no broken links
cd archive && zip -9 -r ../postmarketos-lomiri-m52xq-mainline-vN.zip . && cd ..   # from inside the folder, no prefix
unzip -t postmarketos-lomiri-m52xq-mainline-vN.zip | tail -1
```
Before packing a root captured from a phone, remove its personal data: `etc/m52xq/{bt_addr,data-sim,sim-mode}`, `lib/firmware/modem*`,
the sensor registry `usr/share/qcom/…/sensors/registry/*`, Wi-Fi `*.nmconnection` (except `m52xq-mobile-internet`), `var/lib/bluetooth/*`,
`etc/ssh/ssh_host_*`, `etc/machine-id` (leave empty), history, caches, logs (`build/v3/clean-image-v3.sh`).

## 9. Rebuilt programs (`build/`)

| Folder | What was changed |
|---|---|
| `v2/maliit-qt6` | maliit-framework for Qt6 (CMake from master and PR 125) |
| `v3/integratedlightdm` | LightDM stub for Lomiri without lightdm (patches 0001–0006, APKBUILD) |
| `v3/lomiri-app-launch` | `0002-m52xq-posix-reap-children-per-app-pids-stop` — stopping an app's processes |
| `v3/lomiri-launcher`, `v3/lomiri-shell` | launcher index taken at press time; two wallpapers (desktop / lock screen) |
| `v3/lomiri-system-settings` | "About" for mainline (IMEI from ModemManager, OS, apk licenses), brightness, Russian translation |
| `v3/lomiri-camera-app`, `v5/lomiri-camera-app` | optional QZXing, 4K video, 16 MP binned |
| `v3/m52xqcamsrc`, `v5/m52xqcamsrc` | own GStreamer camera source with Venus hardware encoding and autofocus |
| `v3/libcamera` | APKBUILD + soft-ISP patches (S5KGW3 tetracell remosaic, no sensor writes without AGC) |
| `v3/plasma-dialer`, `v4/dialer-*`, `v4/incoming-call` | 2 SIMs, calls over the lock screen, no fullscreen mode, "add contact", SIM in the log, call decision in Lomiri |
| `v4/spacebar-multimodem` | SMS on several modems |
| `v4/calls-lockedapp` | Shell.qml: dialer over the lock screen |
| `v3/powerkey` | `m52xq-powerkey` v2: idle, "keep screen on", suspend |
| `v3/qmlkonsole` | key bar above the on-screen keyboard |
| `v3/aa-shim`, `v3/cellular`, `v3/indicator-bluetooth` | AppArmor stub for click, cellular settings module, Bluetooth indicator |
| `v3/translations` | Russian translations of settings and the power indicator |
| `v5/ath11k-ahb` | `ahb.c` with resume retries (WoWLAN) |

Builds run in a pmbootstrap (aarch64) chroot or an Alpine chroot; the exact commands of every build are in
`docs/КОМАНДЫ-УБУНТУТАЧ24.md` and `docs/ЖУРНАЛ-УБУНТУТАЧ24.md`.

## 10. Services and scripts of the Lomiri layer

| Service / script | Purpose |
|---|---|
| `m52xq-start-lomiri` | starts the Lomiri session (PATH with lomiri-bin, QML2_IMPORT_PATH, GRID_UNIT_PX=21) |
| `m52xq-powerkey` (+ .service) | short power key press: lock and blank / screen on, suspend |
| `m52xq-osk-bridge` | on-screen keyboard for text-input-v3 (Firefox): input_method_v2 ↔ maliit-server |
| `m52xq-ringtone` | ringtone and vibration for an incoming modem call |
| `m52xq-incall-proximity` | blanks the screen at the ear during calls |
| `m52xq-messaging-bridge` | unread SMS in the Lomiri messaging indicator |
| `m52xq-sim-slots`, `m52xq-indicator-sim`, `m52xq-sim-mode-menu` | slot of every SIM (ICCID), SIMs in the shade, SIM mode menu |
| `m52xq-gnss-gpsd` | ModemManager GNSS (NMEA) → gpsd for lomiri-location-service |
| `m52xq-wow-params`, `m52xq-wifi-*`, `m52xq-timesyncd.sh` | WoW flags, Wi-Fi in sleep, time sync after sleep |
| `m52xq-audio-reprobe` | retries the LPASS VA macro probe after the ADSP start race |
| `m52xq-reboot-recovery` | power menu: reboot to recovery |
| `m52xq-app-env` | application launch environment (scale, Qt variables) |
| `m52xq-camera-postprocess` | camera photo post-processing |

The shared hardware services (modem, audio, sensors, Wi-Fi, sleep, NFC) are in the Plasma port repository.

## 11. Pitfalls

- Lomiri telephony (`lomiri-telephony-service`) needs telepathy-ofono, while our modem runs through ModemManager — so calls and SMS use plasma-dialer and Spacebar.
- `iio-sensor-proxy` rotated application windows and touches missed them; in 003 it is masked and the orientation is portrait.
- Do not install dev packages that downgrade systemd/libc; `apk upgrade` replaces our builds.
- `pkill -f` inside an ssh command kills its own session — stop processes by PID.
- Build the zip only from inside the archive folder (`cd archive && zip -9 -r ../x.zip .`), otherwise TWRP does not find `META-INF`.
- `losetup` of the image needs `--sector-size 4096`, otherwise p1/p2 are not visible.

## 12. Credits
postmarketOS and pmbootstrap; UBports and Lomiri; KDE (plasma-dialer, Spacebar); the mainline Linux developers for Qualcomm SC7280/QCM6490.
