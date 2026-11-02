#!/bin/sh
# M52XQ (убунтутач24/003, в4): systemd-timesyncd asks the NTP server before every sleep (it re-syncs after each Wi-Fi reset by NetworkManager),
# the reply (UDP :123, a unicast frame the APF passes) wakes the phone ~0.6 s after it fell asleep, again and again every ~25 s.
# No NTP traffic during sleep: stop timesyncd before suspend, start it again only after a wake-up that was not caused by Wi-Fi
# (power key / modem...); after a Wi-Fi wake-up (dark resume) it stays stopped.
case "$1" in
pre)
	systemctl stop systemd-timesyncd.service >/dev/null 2>&1
	;;
post)
	irq=$(cat /sys/power/pm_wakeup_irq 2>/dev/null)
	ce2=$(awk '$NF == "ce2" { sub(":", "", $1); print $1 }' /proc/interrupts)
	[ -n "$irq" ] && [ "$irq" = "$ce2" ] && exit 0
	systemctl start --no-block systemd-timesyncd.service >/dev/null 2>&1
	;;
esac
exit 0
