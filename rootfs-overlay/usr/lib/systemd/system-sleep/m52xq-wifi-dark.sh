#!/bin/sh
# M52XQ: "dark" resume after a Wi-Fi wake-up. With WoW + APF (boot v228) the Wi-Fi firmware wakes the system for a packet
# to us (WOW reason 39 BPF_ALLOW, interrupt ce2), like the stock Android. Plasma then turns the display on and the phone
# stays awake until the normal auto-suspend (60 s + 120 s); m52xq-wifi-dark keeps the display off and suspends again.
# boot v230: the panel driver keeps the display off for $DARK s (dark_resume, set here before user space is thawed), so
# the display no longer flashes; m52xq-wifi-dark ends it (0) when the phone stays awake. Any other wake-up: display on.
DR=/sys/module/panel_samsung_s6e3hab_amb667an01/parameters/dark_resume
DARK=40
# m52xq (в4): the panel stays powered (display off by brightness 0) over the sleep; when the kernel resumes the DRM output before this hook
# runs ("post"), the panel is prepared + enabled at once: a full-brightness flash on black for a fraction of a second at every wake-up
# (seen with an SMS). The driver's dark window is counted in jiffies, which do not run in s2idle, so it is armed BEFORE the sleep; "post"
# below keeps it (Wi-Fi / modem wake-up) or ends it (anything else: key, alarm).
if [ "$1" = pre ]; then
	[ -w $DR ] && echo $DARK > $DR
	exit 0
fi
[ "$1" = post ] || exit 0	# boot v232+: the power / volume keys end the dark window in the panel driver
irq=$(cat /sys/power/pm_wakeup_irq 2>/dev/null)
ce2=$(awk '$NF == "ce2" { sub(":", "", $1); print $1 }' /proc/interrupts)
# v42: a packet over mobile data wakes the system through the IPA (irq "ipa") - the same dark resume as Wi-Fi.
# Calls and SMS come over QMI (glink-smem / qrtr-voice-sms): no interrupt number at all (pm_wakeup_irq: ENODATA, empty here).
# m52xq (в4): that wake-up is dark as well (an SMS flashed the backlight); m52xq-wifi-dark turns the display on when a call rings.
ipa=$(awk '$NF == "ipa" { sub(":", "", $1); print $1 }' /proc/interrupts)
case "$irq" in
"") wake=modem ;;
"$ce2") wake=Wi-Fi ;;
"$ipa") wake="mobile data" ;;
*) wake= ;;
esac
if [ -z "$wake" ]; then
	[ -w $DR ] && echo 0 > $DR
	exit 0
fi
[ -w $DR ] && echo $DARK > $DR
systemd-run --no-block --collect --unit=m52xq-wifi-dark --setenv=WAKE="$wake" /usr/local/bin/m52xq-wifi-dark >/dev/null 2>&1
exit 0
