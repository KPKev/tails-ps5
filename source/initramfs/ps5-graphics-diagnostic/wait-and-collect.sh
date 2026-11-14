#!/bin/sh
set -u
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH LC_ALL=C SYSTEMD_PAGER=cat PAGER=cat
# Capture early; journal and logind polling can miss a short-lived shell.
watchdir=$(mktemp -d /run/ps5-shell-watch.XXXXXXXX) || exit 1
chmod 700 "$watchdir"
watchpid=
cleanup_watch() {
    if [ -n "$watchpid" ]; then kill "$watchpid" 2>/dev/null || :; wait "$watchpid" 2>/dev/null || :; fi
    rm -rf "$watchdir"
}
trap cleanup_watch EXIT
trap 'exit 1' HUP INT TERM
/usr/bin/python3 /usr/local/libexec/ps5-shell-watch "$watchdir/selected.txt" &
watchpid=$!
# GDM PAM session is durable in the current boot journal even if the user shell crashes.
# loginctl is a second signal, not a generic amnesia-owned process (which exists at greeter).
count=0
trigger=timeout_no_login_observed
while [ "$count" -lt 240 ]; do
    if timeout 5 journalctl -b --no-pager -n 500 -u gdm.service 2>/dev/null | grep -Eq 'session opened for user amnesia([ (]|$)'; then
        trigger=gdm_amnesia_session_opened
        break
    fi
    if timeout 5 loginctl list-sessions --no-legend 2>/dev/null | awk '$3 == "amnesia" { found=1 } END { exit !found }'; then
        trigger=logind_amnesia_session
        break
    fi
    sleep 5
    count=$((count + 1))
done
if [ "$trigger" != timeout_no_login_observed ]; then sleep 15; fi
kill "$watchpid" 2>/dev/null || :
wait "$watchpid" 2>/dev/null || :
watchpid=
/bin/sh /usr/local/libexec/ps5-graphics-diagnostic "$trigger" "$watchdir/selected.txt"
