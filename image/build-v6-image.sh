#!/bin/bash
# 003 в6 (2026-11-09): release-style image "v1-v6" of postmarketOS + Lomiri: a snapshot of the test phone (all в6 fixes installed)
# over USB into a fresh ext4 that keeps the partition layout, pmOS_boot and the clean /home skeleton of the v3 image (OLD).
# Removed: personal data (home, Wi-Fi networks, Bluetooth pairings, SIM choices, logs, keys, machine-id) and the proprietary
# firmware / sensor configs that the installer copies from the phone itself (pm v2 installer blocks).
# Usage: OLD=base-v3.img NEW=out.img PATTERNS=file ./build-v6-image.sh   (run as the user with sudo -n)
set -eu
# <HOME-WIFI>: put the names of your own Wi-Fi profiles here (they must not go into a public image)
W=${W:-/home/sasha/003-v6-build}; OLD=${OLD:-$W/base-v3.img}; NEW=${NEW:-$W/samsung-m52xq-lomiri-v1-v6.img}
PATTERNS=${PATTERNS:?file with personal values, one per line}
MNT=$W/mnt-new; OLDM=$W/mnt-old; LOG=$W/build.log; mkdir -p $MNT $OLDM
SSH="sshpass -p 1111 ssh -o ConnectTimeout=8 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAuthentication=no -o LogLevel=ERROR user@172.16.42.1"
G=/usr/bin/grep
[ ! -e $NEW ] || { echo "$NEW exists"; exit 1; }
LO=$(sudo -n losetup -f --show -r -P --sector-size 4096 $OLD)
dd if=$OLD of=$NEW bs=4096 count=124928 status=none; truncate -s $(stat -c %s $OLD) $NEW
L=$(sudo -n losetup -f --show -P --sector-size 4096 $NEW)
sudo -n mkfs.ext4 -F -q -L pmOS_root -U 27c97050-ff55-4e42-b894-0f866eb5ad1f -b 4096 -N 327680 -m 5 -E lazy_itable_init=0,lazy_journal_init=0 ${L}p2
sudo -n mount ${L}p2 $MNT; sudo -n mount -o ro,noload ${LO}p2 $OLDM
sudo -n mkdir -p $MNT/home; sudo -n cp -a $OLDM/home/. $MNT/home/
echo "== tar $(date +%T)"
# GNU tar 1.35 (Alpine aarch64 apk, /tmp/gtar on the phone: busybox tar keeps no xattrs / file capabilities).
# the phone must not sleep during the copy: systemd-inhibit (root: sudo -S reads the password from the first line of stdin)
$SSH 'echo 1111 | sudo -S -p "" sh -c "cd / && systemd-inhibit --what=sleep:idle --who=snapshot --why=image /tmp/gtar --one-file-system --xattrs --xattrs-include=* --numeric-owner -cf - \
 --exclude=./proc/* --exclude=./sys/* --exclude=./dev/* --exclude=./run/* --exclude=./tmp/* --exclude=./mnt/* --exclude=./media/* \
 --exclude=./boot/* --exclude=./root/* --exclude=./root/.[!.]* --exclude=./home/* --exclude=./lost+found \
 --exclude=./var/log/* --exclude=./var/cache/* --exclude=./var/tmp/* --exclude=./var/crash/* --exclude=./var/lib/systemd/coredump/* \
 --exclude=./var/lib/systemd/random-seed --exclude=./var/lib/NetworkManager/* --exclude=./var/lib/bluetooth/* --exclude=./var/lib/upower/* \
 --exclude=./var/lib/AccountsService/users/* --exclude=./var/lib/AccountsService/icons/* --exclude=./var/lib/sudo/* \
 --exclude=./etc/NetworkManager/system-connections/<HOME-WIFI>* --exclude=./etc/shadow- --exclude=./etc/.m52xq-shadow-backup \
 --exclude=./etc/m52xq/bt_addr --exclude=./etc/m52xq/data-sim --exclude=./etc/m52xq/sim-mode --exclude=./etc/m52xq/sms-sim \
 --exclude=./etc/m52xq-soclog-verbose --exclude=./etc/ssh/ssh_host_* --exclude=./usr/local/bin/m52xq-mpx-debug \
 --exclude=./usr/share/qcom/sm7325/Samsung/m52xq/sensors/registry/* --exclude=./usr/share/qcom/sm7325/Samsung/m52xq/sensors/config/* \
 --exclude=./usr/share/qcom/sm7325/Samsung/m52xq/sensors/sns_reg.conf \
 --exclude=./lib/firmware/adsp* --exclude=./lib/firmware/modem* --exclude=./lib/firmware/a660_zap* --exclude=./lib/firmware/yupik_ipa_fws* \
 --exclude=./lib/firmware/qca/* --exclude=./lib/firmware/qcom/vpu-2.0/* . ; echo tar-rc=\$? >&2"' 2>$W/tar.err | sudo -n tar --xattrs --xattrs-include='*' --numeric-owner -xpf - -C $MNT
tail -3 $W/tar.err | cut -c1-140; $G -q 'tar-rc=[01]$' $W/tar.err || { echo TAR-FAILED; exit 1; }
for d in var/lib/AccountsService/users var/lib/AccountsService/icons; do
	sudo -n mkdir -p $MNT/$d; [ -d $OLDM/$d ] && sudo -n cp -a $OLDM/$d/. $MNT/$d/ || true
done
sudo -n umount $OLDM; sudo -n losetup -d $LO
echo "== fixups $(date +%T)"
$SSH 'cd / && find var/log var/cache var/tmp -xdev -type d -print0 2>/dev/null | tar --no-recursion --null -T - --numeric-owner -cf -' 2>/dev/null | sudo -n tar --numeric-owner -xpf - -C $MNT || true
sudo -n mkdir -p $MNT/root $MNT/tmp $MNT/run $MNT/proc $MNT/sys $MNT/dev; sudo -n chmod 700 $MNT/root; sudo -n chmod 1777 $MNT/tmp
H=$(openssl passwd -6 1111)
sudo -n env H="$H" awk 'BEGIN{FS=OFS=":"} $1=="root"||$1=="user"{$2=ENVIRON["H"]} {print}' $MNT/etc/shadow > $W/shadow.new
sudo -n sh -c "cat $W/shadow.new > $MNT/etc/shadow"; rm -f $W/shadow.new
sudo -n sh -c ": > $MNT/etc/machine-id"; [ -L $MNT/var/lib/dbus/machine-id ] || sudo -n rm -f $MNT/var/lib/dbus/machine-id
echo "lomiri v1-v6" | sudo -n tee $MNT/etc/m52xq/lomiri-v5 >/dev/null
sync; df -B1 $MNT | tail -1 | awk '{print "used",$3,"free",$4}'
echo "== scan $(date +%T)"
umask 077
$SSH 'echo 1111 | sudo -S -p "" sh -c "cat /etc/m52xq/bt_addr; echo; cat /sys/class/net/wl*/address 2>/dev/null; for m in \$(mmcli -L 2>/dev/null | sed -n \"s#.*/Modem/\([0-9]*\).*#\1#p\"); do mmcli -m \$m -K 2>/dev/null | sed -n \"s/.*equipment-identifier *: *//p; s/.*own-numbers.value.*: *//p\"; S=\$(mmcli -m \$m -K 2>/dev/null | sed -n \"s#.*generic.sim *: */org/freedesktop/ModemManager1/SIM/##p\"); [ -n \"\$S\" ] && mmcli -i \$S -K 2>/dev/null | sed -n \"s/.*sim.properties.imsi *: *//p; s/.*sim.properties.iccid *: *//p\"; done; sed -n \"s/^\(root\|user\):\([^:]*\):.*/\2/p\" /etc/shadow"' 2>/dev/null > $W/p0.txt
cat "$PATTERNS" >> $W/p0.txt
/usr/bin/python3 -I - "$W" <<'P'
import sys
d=sys.argv[1]; out=set(); skip={'lo','--'}
for l in open(d+'/p0.txt',errors='ignore'):
    l=l.strip()
    if len(l)<5 or l in skip: continue
    out|={l,l.lower(),l.upper()}
    if l.count(':')==5: out|={l.replace(':',''),l.replace(':','').lower()}
open(d+'/p.txt','w').write('\n'.join(sorted(out))+'\n'); print('patterns',len(out))
P
sudo -n $G -rlaF -f $W/p.txt $MNT 2>/dev/null | sed "s#^$MNT/##" > $W/hits.txt || true
echo hits=$(wc -l < $W/hits.txt); head -14 $W/hits.txt
rm -f $W/p0.txt $W/p.txt
for f in etc/m52xq/bt_addr lib/firmware/adsp.mdt lib/firmware/modem.mdt lib/firmware/a660_zap.mdt lib/firmware/qca/msnv11.bin lib/firmware/qcom/vpu-2.0/venus.mbn lib/firmware/yupik_ipa_fws.mdt usr/share/qcom/sm7325/Samsung/m52xq/sensors/sns_reg.conf; do sudo -n test -e $MNT/$f && echo "HAS $f"; done
echo keep: $(sudo -n ls $MNT/lib/firmware/wpss.mdt $MNT/lib/firmware/a660_sqe.fw 2>&1 | wc -l) ssh: $(sudo -n ls $MNT/etc/ssh | $G -c ssh_host) wifi-conns: $(sudo -n ls $MNT/etc/NetworkManager/system-connections | tr '\n' ' ') home: $(sudo -n du -sh $MNT/home | cut -f1)
sudo -n umount $MNT; sudo -n e2fsck -fn ${L}p2 2>&1 | tail -1; sudo -n losetup -d $L
md5sum $NEW | tee $NEW.md5
echo BUILD-OK-$(date +%T)
