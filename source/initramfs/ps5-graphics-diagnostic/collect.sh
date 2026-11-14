#!/bin/sh
set -u
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH LC_ALL=C SYSTEMD_PAGER=cat PAGER=cat
medium=/lib/live/mount/medium
uuid=618F-B6CA
link=/dev/disk/by-uuid/$uuid
log() { printf '%s\n' "PS5_GRAPHICS_DIAG: $*" > /dev/kmsg 2>/dev/null || :; }
fail() { log "ABORT: $*"; exit 1; }
work=$(mktemp -d /run/ps5-graphics-diag.XXXXXXXX) || exit 1
rw=0
cleanup() {
    if [ "$rw" = 1 ]; then
        sync
        if mount -o remount,ro "$medium"; then log 'live medium returned to read-only'; else log 'ERROR: could not restore live medium read-only'; fi
    fi
    rm -rf "$work"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
boot_id=$(cat /proc/sys/kernel/random/boot_id) || fail 'missing boot id'
case "$boot_id" in *[!0-9a-f-]*|'') fail 'invalid boot id' ;; esac
[ "${#boot_id}" = 36 ] || fail 'invalid boot id length'
case " $(cat /proc/cmdline) " in *' FSUUID=618F-B6CA '*) ;; *) fail 'boot UUID argument differs' ;; esac
case " $(cat /proc/cmdline) " in *' ps5_graphics_diagnostic=1 '*) ;; *) fail 'diagnostic not enabled' ;; esac
[ -b "$link" ] || fail 'UUID device missing'
dev=$(readlink -f "$link") || fail 'UUID resolution failed'
[ "$(blkid -c /dev/null -s UUID -o value "$dev")" = "$uuid" ] || fail 'UUID verification failed'
[ "$(blkid -c /dev/null -s TYPE -o value "$dev")" = vfat ] || fail 'not VFAT'
devices=$(blkid -c /dev/null -t "UUID=$uuid" -o device) || fail 'UUID scan failed'
[ "$(printf '%s\n' "$devices" | wc -l)" -eq 1 ] || fail 'UUID not unique'
[ "$(readlink -f "$devices")" = "$dev" ] || fail 'UUID scan mismatch'
[ "$(findmnt -n -M "$medium" -o FSTYPE)" = vfat ] || fail 'live medium is not VFAT'
mounted=$(findmnt -n -M "$medium" -o MAJ:MIN) || fail 'live medium is not mounted'
device_num=$(lsblk -dn -o MAJ:MIN "$dev") || fail 'cannot identify device number'
[ "$mounted" = "$device_num" ] || fail 'live medium and UUID device differ'
opts=$(findmnt -n -M "$medium" -o OPTIONS) || fail 'mount options unavailable'
case ",$opts," in *,ro,*) ;; *) fail 'live medium was not read-only' ;; esac
section() { printf '\n=== %s ===\n' "$1"; }
capture() {
    printf '\n$'; printf ' %s' "$@"; printf '\n'
    timeout 12 "$@" 2>&1 | head -c 262144
    printf '\n[section ended; limit 262144 bytes / 12 seconds]\n'
}
{
    section 'Trigger'
    printf 'trigger=%s\n' "${1:-unknown}"
    section 'Early user shell observer (selected fields only)'
    if [ -f "${2:-/nonexistent}" ]; then head -c 65536 "$2"; [ "$(wc -c < "$2")" -le 65536 ] || echo "[observer output truncated at 65536 bytes]"; else echo '[watcher output unavailable]'; fi
    section 'Identity' 
    capture date -u
    capture uname -a
    printf 'boot_id=%s\n' "$boot_id"
    capture cat /proc/cmdline
    section 'Display and graphics services'
    capture systemctl --no-pager --plain --failed
    capture loginctl list-sessions --no-legend
    uid=$(id -u amnesia 2>/dev/null || :)
    if [ -n "$uid" ] && [ -d "/run/user/$uid" ]; then
        capture runuser -u amnesia -- env XDG_RUNTIME_DIR=/run/user/$uid DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus systemctl --user --no-pager --plain --failed
        capture runuser -u amnesia -- env XDG_RUNTIME_DIR=/run/user/$uid DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus systemctl --user show org.gnome.Shell@wayland.service -p Id -p LoadState -p ActiveState -p SubState -p Result -p MainPID -p NRestarts
    fi
    capture systemctl show gdm.service -p Id -p LoadState -p ActiveState -p SubState -p Result -p MainPID -p NRestarts
    capture ps -eo pid,ppid,user,comm
    section 'Active DRM state if available'
    count=0
    for f in /sys/kernel/debug/dri/[0-9]*/state; do
        [ -r "$f" ] || continue
        count=$((count + 1))
        [ "$count" -le 4 ] || { echo 'DRM state limit reached'; break; }
        printf '\n--- %s ---\n' "$f"
        head -c 32768 "$f"
    done
    [ "$count" -gt 0 ] || echo '[DRM state unavailable]'
    section 'Current boot GDM journal'
    capture journalctl -b --no-pager -n 500 -u gdm.service
    section 'Current boot GNOME Shell journal'
    capture journalctl -b --no-pager -n 500 _COMM=gnome-shell
    section 'Current boot graphics and fault kernel lines'
    timeout 12 journalctl -b --no-pager -n 1500 -k 2>&1 | grep -Ei 'gnome-shell|segfault|general protection|amdgpu|drm|gpu|fault' | tail -n 300 | head -c 262144 || :
    section 'DRM devices and connector status'
    capture ls -l /dev/dri /sys/class/drm /sys/class/graphics
    for f in /sys/class/drm/card*-*/status /sys/class/drm/card*-*/modes /sys/class/graphics/fb*/name; do
        [ -r "$f" ] || continue
        printf '\n--- %s ---\n' "$f"
        head -c 16384 "$f"
    done
    section 'Graphics modules'
    capture lsmod
    section 'Offline network and service state (read-only snapshot)'
    capture ip -brief address
    capture ip -4 route show table all
    capture ip -6 route show table all
    capture ip netns list
    capture nmcli device status
    capture systemctl show ferm.service tails-create-netns.service tor.service tor@default.service tails-wait-until-tor-has-bootstrapped.service apparmor.service NetworkManager.service -p Id -p LoadState -p ActiveState -p SubState -p Result -p ExecMainCode -p ExecMainStatus
    capture journalctl -b --no-pager -n 100 -u ferm.service -u tails-create-netns.service -u tor.service -u tor@default.service -u apparmor.service
    section 'Firewall backends and main namespace rules'
    capture iptables --version
    capture ip6tables --version
    capture iptables-save -c
    capture ip6tables-save -c
    capture nft list ruleset
    section 'Existing Tails namespace firewall rules and routes'
    for ns in tbb onioncircs tca onionshare clearnet; do
        if [ -e "/run/netns/$ns" ]; then
            capture ip netns exec "$ns" iptables-save -c
            capture ip netns exec "$ns" ip6tables-save -c
            capture ip netns exec "$ns" ip -4 route show table all
            capture ip netns exec "$ns" ip -6 route show table all
        else
            printf '[namespace absent: %s]\n' "$ns"
        fi
    done
    section 'AppArmor state'
    capture cat /sys/kernel/security/lsm
    capture cat /sys/module/apparmor/parameters/enabled
    capture aa-status
} > "$work/report.txt" 2>&1 || fail 'cannot stage report'
[ "$(wc -c < "$work/report.txt")" -le 9000000 ] || fail 'report exceeded size limit'
# The selected live medium is already mounted read-only. Do not mount any
# other filesystem, and never make a second writable alias of this VFAT.
mount -o remount,rw "$medium" || fail 'cannot remount verified live medium read-write'
rw=1
opts=$(findmnt -n -M "$medium" -o OPTIONS) || fail 'cannot verify writable mount'
case ",$opts," in *,rw,*) ;; *) fail 'mount is not writable' ;; esac
out="$medium/PS5-DIAG-$boot_id"
mkdir "$out" || fail 'new output directory already exists or cannot be created'
cp "$work/report.txt" "$out/report.txt" || fail 'report write failed'
sync
log "saved report in PS5-DIAG-$boot_id"
exit 0
