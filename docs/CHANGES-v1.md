# Changes in unofficial v1 (first public release)

Audience: users of the port and developers who want to know what changed since the archive v5 (2026-10-30) and why.
Details with md5 sums and test logs: `docs/ЧТО_НОВОГО-v6.txt`, `-v7.txt`, `-v8.txt` (Russian).

| | v5 (2026-10-30) | unofficial v1 (2026-11-10) |
|---|---|---|
| Kernel | 7.1.2 #430 | 7.1.13 + q6voice, panel and ath11k patches (`kernel/`) |
| Device tree | downstream style | upstream-style DTB + local nodes, RTC enabled |
| dtbo | unchanged | `dtbo-frag` written by the installer |
| Image | snapshot of one phone | clean image: no personal data, keys or proprietary firmware |
| Zip | `postmarketos-lomiri-m52xq-mainline-v5.zip` | `postmarketos-lomiri-m52xq-mainline-v1-UNOFFICIAL.zip`, md5 `eba0bbd593c733a6f49ccc6ab4d63ac2` |

A clean install is required (Format Data).

## Installer and image
- **No proprietary firmware in the zip.** DSP, GPU zap shader, IPA, Venus, modem, Bluetooth firmware, sensor configs and the
  Bluetooth address come from the phone's own partitions during the install (installer of the postmarketOS Plasma port).
- Release image: a snapshot of a configured phone (`image/build-v8-image.sh`) without home data, Wi-Fi networks, Bluetooth
  pairings, SIM choices, logs, SSH keys, machine ID; password 1111; checked for personal values.
- Time zone chosen in the wizard is applied: the stock systemd-timedated policy asks for an admin password, Lomiri asks without
  one and the change was refused silently (`etc/polkit-1/rules.d/50-m52xq-timedate.rules`).

## Kernel
- Calls: speaker/earpiece switching without new voice sessions (the audio DSP no longer crashes).
- Display: no flash on network wake-ups (the panel stays asleep while the brightness is 0).
- Wi-Fi off really sleeps (ath11k power save with the radio off).
- RTC enabled: the alarm wakes the phone from sleep.

## Calls, SIM and mobile data
- Incoming call in sleep: the screen turns on; after the call the lock screen comes back. Before, the dialer stayed "locked"
  over the lock screen and edge swipes, the shade and the dial pad did not react until a lock/unlock (`Shell.qml`).
- Fast taps on the dial pad are no longer lost (Kirigami ColumnView ran an empty slide animation on every tap: patch for 6.31,
  `build/v7/kirigami`).
- SIM manager: SIM cards power, mode, the SIM of the mobile data and a mobile data switch; the data SIM buttons are greyed out
  while the data are off; the switch is in sync with the quick settings in both directions; after a SIM/mode switch the data
  come back up on the new SIM.
- Quick settings: the mobile data switch no longer flickers every few seconds.
- ModemManager crash on data connects fixed (use-after-free), KPeople crash fixed (database used by two threads).

## Telegram Desktop
- Wi-Fi stays connected over a suspend: the sleep hook re-armed WoWLAN with a wrong `iw` path, so NetworkManager dropped Wi-Fi
  before every sleep.
- A Wi-Fi wake-up keeps the phone awake for 45 s while Telegram runs (it needs that long to reconnect after a long sleep).
- The screen turns on when a Telegram call rings in sleep, and the phone does not suspend or blank during a ring or a call.
- Call audio moves to the earpiece (the playing stream is reopened; on 7.1.13 a routing change alone did not move it).

## GPS
- XTRA assistance data downloaded and injected after boot (`m52xq-gps-xtra` + timer): before, a cold start got no fix even at a window.
- NMEA from ModemManager is passed to gpsd in order (gpsd reported "no fix" every other second).
- lomiri-location-service passed no position at all with gpsd ≥ 3.20 (it checks a deprecated altitude field): LD_PRELOAD shim
  `m52xq-gps-alt` (`build/v7/gps`).

## Camera
- Digital zoom up to 4x in the camera source (viewfinder, photo, video) and the zoom slider fits in landscape.
- Megapixels adapted to Lomiri (scale, controls in portrait and landscape).

## Known issues
- Rarely the Wi-Fi firmware crashes during a long sleep; a reboot brings Wi-Fi back.
- After switching networks the Wi-Fi icon can disappear while connected; a reboot fixes it.
- `apk upgrade` replaces the patched packages of the port; do not run a full upgrade.
