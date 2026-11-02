# samsung-m52xq-postmarketos-lomiri

postmarketOS + **Lomiri** (the Ubuntu Touch shell) on a **mainline Linux kernel** for the
**Samsung Galaxy M52 5G** (codename `m52xq`, SM-M526B / SM-M526BR, Qualcomm Snapdragon 778G / SM7325).

No Halium, no libhybris, no Android kernel: mainline Linux 7.1.2 (build #430), postmarketOS edge, Lomiri 0.6.2, **no Plasma**.
Sister project of [samsung-m52xq-mainline](https://github.com/korryasdlerto-lgtm/samsung-m52xq-mainline) (Plasma Mobile),
which holds the shared hardware layer. Personal, unofficial project, tested on one SM-M526B.

**Status (archive "lomiri v5", 2026-10-30):** calls and SMS on two SIMs, mobile data, Wi-Fi with wake-on-WLAN in sleep, Bluetooth,
GPU-accelerated Lomiri, sound, camera with hardware video encoding (1080p / 4K), GPS (outdoors), suspend.

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

Plus the full work log with every command (Russian): [docs/ЖУРНАЛ-УБУНТУТАЧ24.md](docs/ЖУРНАЛ-УБУНТУТАЧ24.md),
[docs/КОМАНДЫ-УБУНТУТАЧ24.md](docs/КОМАНДЫ-УБУНТУТАЧ24.md).

## Kernel

Release **[kernel-7.1.2-430](../../releases/tag/kernel-7.1.2-430)**: `boot_v241_nfc.img`, `vendor_boot_v238_nfc_se9.img`, `Image`,
`config-7.1.2-430`, `modules-7.1.2-430.tar.gz` (with the v5 `ath11k_ahb.ko`), `SHA256SUMS`.
Source: [sc7280-mainline-linux-m52xq](https://github.com/korryasdlerto-lgtm/sc7280-mainline-linux-m52xq).

## What works

| Feature | Status | Notes |
|---|---|---|
| Lomiri shell, display, GPU, touch | works | Mir on gbm-kms + Mesa freedreno |
| On-screen keyboard | works | maliit Qt6, bridge for text-input-v3 apps (Firefox) |
| Calls, SMS, two SIMs, mobile data | works | plasma-dialer and Spacebar adapted to Lomiri, ModemManager DSDS |
| Wi-Fi, Bluetooth | works | Wi-Fi stays up in sleep and wakes the phone (WoWLAN) |
| Audio | works | |
| Camera | works | lomiri-camera-app + own GStreamer source, Venus video 1080p / 4K ≤ 24 fps |
| GPS | partial | gpsd → lomiri-location-service; no fix indoors |
| Suspend | works | wakes for calls, SMS, Wi-Fi packets |
| Fingerprint | no | |

## Layout

| Folder | Contents |
|---|---|
| `installer/` | TWRP installer (`META-INF`) |
| `rootfs-overlay/` | files put over the image in versions 2–5; binaries listed in `EXCLUDED-FILES.txt` |
| `image/` | root build: layer script, package list, repositories, device package, session, boot splash |
| `build/v2…v5/` | sources and patches of every rebuilt program |
| `docs/` | manuals (EN/RU), work log, command log, to-do lists, what's new |

The flashable zip and the system image are not in the repository (they contain a built system); see the manual, section 8.
Personal data of the test phone (Bluetooth address, sensor registry, Wi-Fi, keys) is not included.
