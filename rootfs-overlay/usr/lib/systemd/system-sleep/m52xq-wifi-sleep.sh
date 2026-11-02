#!/bin/sh
# M52XQ (в5): intentionally empty. The v4 script unloaded ath11k_ahb for every sleep (the firmware crashed after a long WoW sleep woken by the power
# key); with flags 0x20 (m52xq-wow-params) and the own ath11k_ahb.ko (resume handshake retries, /etc/modprobe.d/m52xq-ath11k-wow.conf) Wi-Fi stays up
# in sleep and wakes the phone (WoW). Back to the unload: restore the v4 script (003/rootfs of v4: usr/lib/systemd/system-sleep/m52xq-wifi-sleep.sh).
exit 0
