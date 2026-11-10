# samsung-m52xq-postmarketos-lomiri

postmarketOS + **Lomiri** (the Ubuntu Touch shell) on a **mainline Linux kernel** for the
**Samsung Galaxy M52 5G** (codename `m52xq`, SM-M526B / SM-M526BR, Qualcomm Snapdragon 778G / SM7325).

No Halium, no libhybris, no Android kernel: mainline Linux 7.1.13, postmarketOS edge with systemd, Lomiri 0.6.2, **no Plasma**.
Sister project of [samsung-m52xq-mainline](https://github.com/korryasdlerto-lgtm/samsung-m52xq-mainline) (Plasma Mobile),
which holds the shared hardware layer, and of [samsung-m52xq-ubuntu-lomiri](https://github.com/korryasdlerto-lgtm/samsung-m52xq-ubuntu-lomiri)
(the same shell on Ubuntu 26.04). Personal, unofficial project, tested on one SM-M526B.
Wiki page: [User:Asdlerto Korry](https://wiki.nura.eco/wiki/User:Asdlerto_Korry)

**Release: unofficial v1 (2026-11-10)** — `postmarketos-lomiri-m52xq-mainline-v1-UNOFFICIAL.zip`, md5 `eba0bbd593c733a6f49ccc6ab4d63ac2`.
What changed since the archive v5: [docs/CHANGES-v1.md](docs/CHANGES-v1.md) ([русский](docs/CHANGES-v1-RU.md)).

## Videos

| | |
|---|---|
| Installation | https://www.youtube.com/watch?v=7mkKoSjPERk |
| Going back to Android | https://www.youtube.com/watch?v=0lgLbtdl4rA |

## Manuals

| Language | Markdown | Word |
|---|---|---|
| English | [docs/MANUAL-EN.md](docs/MANUAL-EN.md) | [docs/M52-postmarketos-lomiri-manual-EN.docx](docs/M52-postmarketos-lomiri-manual-EN.docx) |
| Русский | [docs/MANUAL-RU.md](docs/MANUAL-RU.md) | [docs/M52-postmarketos-lomiri-manual-RU.docx](docs/M52-postmarketos-lomiri-manual-RU.docx) |

The manuals describe release v1 (install, what works, kernel, how the release image and zip are built); the changes after
the archive v5 are summed up in CHANGES-v1, per version in `docs/ЧТО_НОВОГО-v6.txt` … `-v9.txt`. Full work log with every command (Russian): [docs/ЖУРНАЛ-УБУНТУТАЧ24.md](docs/ЖУРНАЛ-УБУНТУТАЧ24.md),
[docs/КОМАНДЫ-УБУНТУТАЧ24.md](docs/КОМАНДЫ-УБУНТУТАЧ24.md).

## Kernel

Mainline Linux 7.1.13, see [kernel/README.md](kernel/README.md): config, the m52xq patches, and the binaries in release
[kernel-7.1.13](https://github.com/korryasdlerto-lgtm/samsung-m52xq-ubuntu-lomiri/releases/tag/kernel-7.1.13) of samsung-m52xq-ubuntu-lomiri
(the boot images of the v1 zip are byte-identical). Source: [sc7280-mainline-linux-m52xq](https://github.com/korryasdlerto-lgtm/sc7280-mainline-linux-m52xq).

## What works (v1)

| Feature | Status | Notes |
|---|---|---|
| Lomiri shell, display, GPU, touch | works | Mir on gbm-kms + Mesa freedreno; fast taps on the dial pad (patched Kirigami) |
| First-run wizard | works | language, Wi-Fi, time zone (polkit rule for systemd-timedated) |
| On-screen keyboard | works | maliit Qt6, bridge for text-input-v3 apps (Firefox) |
| Calls, SMS, two SIMs, mobile data | works | plasma-dialer and Spacebar adapted to Lomiri, ModemManager DSDS; SIM manager with a mobile data switch in sync with the quick settings |
| Calls in sleep | works | the screen turns on for a modem call; after the call the lock screen comes back (no stuck dialer) |
| Wi-Fi, Bluetooth | works | Wi-Fi stays connected in sleep and wakes the phone (WoWLAN + APF) |
| Telegram Desktop | works | messages and calls arrive in sleep, the screen turns on for a call, call audio in the earpiece |
| Audio | works | loudspeaker, earpiece, microphones, noise suppression |
| Camera | works | lomiri-camera-app + own GStreamer source: digital zoom up to 4x, Venus hardware video; Megapixels |
| GPS | works | ModemManager GNSS → gpsd → lomiri-location-service; XTRA assistance data; Pure Maps |
| Alarm | works | wakes the phone from sleep (RTC) |
| Charging | works | Samsung AFC 9 V fast charging |
| Suspend | works | about 1 % per hour overnight with Wi-Fi connected |
| Fingerprint, VoLTE | no | |

## Layout

| Folder | Contents |
|---|---|
| `installer/` | TWRP installer (`META-INF`) of v1 |
| `rootfs-overlay/` | files put over the system image in versions 2–v1; binaries listed in `EXCLUDED-FILES.txt` (path, size, md5) |
| `image/` | root build: layer script, package lists, repositories, device package, boot splash; `build-v6/v7/v8-image.sh` (release snapshot of a configured phone without personal data and proprietary firmware) |
| `build/v2…v7/` | sources and patches of every rebuilt program |
| `kernel/` | kernel configs and patches |
| `docs/` | manuals (EN/RU), release notes, work log, command log, notes per version |

The flashable zip and the system image are not in the repository (they contain a built system).
Personal data of the test phone (Bluetooth address, sensor registry, Wi-Fi networks, SIM data, keys, coordinates) is not included.
