#!/usr/bin/python3
"""Opt-in, bounded observer. Only sanitized selected fields ever reach disk."""
import os, pwd, re, signal, sys, time

OUT = sys.argv[1]
NAMES = (b'GBM_ALWAYS_SOFTWARE', b'LIBGL_ALWAYS_SOFTWARE', b'GALLIUM_DRIVER', b'GSK_RENDERER')
SAFE = re.compile(rb'^[A-Za-z0-9_.+:-]{0,128}$')
LIB = re.compile(r'^/usr/lib/(?:x86_64-linux-gnu/)?(?:dri/)?(?:lib(?:EGL|GLX|GLdispatch|GL|gbm|gallium|mutter)[A-Za-z0-9_.+\-]*|[A-Za-z0-9_+\-]+_dri\.so)$')
uid = pwd.getpwnam('amnesia').pw_uid
seen = {}
traversal_truncated = False
process_limit_reported = False
stopping = False
def stop(_signum, _frame):
    global stopping
    stopping = True
signal.signal(signal.SIGTERM, stop)
end = time.monotonic() + 600
with open(OUT, 'w', encoding='ascii') as out:
    os.chmod(OUT, 0o600)
    def log(s):
        out.write(s + '\n'); out.flush()
    log('watch_started poll_sleep_seconds=0.1 max_seconds=600 max_processes=8 max_proc_entries=4096')
    while not stopping and time.monotonic() < end:
        active = set()
        entries = os.listdir('/proc')
        if len(entries) > 4096 and not traversal_truncated:
            log('proc_entries_truncated limit=4096')
            traversal_truncated = True
        for pid in entries[:4096]:
            if not pid.isdecimal(): continue
            p = '/proc/' + pid
            try:
                if open(p + '/comm', 'rb').read(32).strip() != b'gnome-shell': continue
                status = open(p + '/status', 'rb').read(8192)
                match = re.search(rb'^Uid:\s+(\d+)', status, re.M)
                if not match or int(match.group(1)) != uid: continue
                stat = open(p + '/stat', 'rb').read(4096)
                start = stat[stat.rfind(b')') + 2:].split()[19].decode('ascii')
                exe = os.readlink(p + '/exe')
                if exe != '/usr/bin/gnome-shell': continue
                key = (pid, start)
                if key not in seen:
                    if len(seen) >= 8:
                        if not process_limit_reported:
                            log('process_limit_reached limit=8'); process_limit_reported = True
                        continue
                    seen[key] = {'env': False, 'env_captured': False, 'maps': set(), 'errors': set()}
                    log('process pid=%s start_ticks=%s exe=/usr/bin/gnome-shell uid=%d' % (pid, start, uid))
                active.add(key)
                item = seen[key]
                if not item['env']:
                    try:
                        with open(p + '/environ', 'rb') as f: data = f.read(1048577)
                        if len(data) > 1048576: log('pid=%s environment=too_large' % pid); item['env'] = True
                        elif not data:
                            if 'environment_empty' not in item['errors']:
                                log('pid=%s environment_empty_or_process_exiting' % pid); item['errors'].add('environment_empty')
                        else:
                            fields = dict(x.split(b'=', 1) for x in data.split(b'\0') if b'=' in x)
                            # Verify PID identity after reads before committing selected values.
                            stat2 = open(p + '/stat', 'rb').read(4096)
                            if stat2[stat2.rfind(b')') + 2:].split()[19].decode('ascii') != start: continue
                            log('pid=%s environment=read' % pid)
                            for name in NAMES:
                                val = fields.get(name)
                                if val is None: log('%s=[unset]' % name.decode())
                                elif SAFE.fullmatch(val): log('%s=%s' % (name.decode(), val.decode('ascii')))
                                else: log('%s=[value omitted]' % name.decode())
                            item['env'] = True
                            item['env_captured'] = True
                        del data
                    except (OSError, ValueError, IndexError) as e:
                        label = 'environment_unavailable_errno_%s' % getattr(e, 'errno', 'unknown')
                        if label not in item['errors']: log('pid=%s %s' % (pid, label)); item['errors'].add(label)
                try:
                    with open(p + '/maps', encoding='utf-8', errors='replace') as f:
                        content = f.read(1048577)
                        if len(content) > 1048576 and 'maps_truncated' not in item['errors']:
                            log('pid=%s maps_truncated limit=1048576' % pid); item['errors'].add('maps_truncated')
                        lines = content[:1048576].splitlines()
                        paths = {line.split(None, 5)[5].strip() for line in lines if len(line.split(None, 5)) == 6}
                    stat2 = open(p + '/stat', 'rb').read(4096)
                    if stat2[stat2.rfind(b')') + 2:].split()[19].decode('ascii') != start: continue
                    for path in sorted(paths):
                        if LIB.fullmatch(path) and path not in item['maps']:
                            if len(item['maps']) < 64: log('pid=%s mapped=%s' % (pid, path)); item['maps'].add(path)
                except OSError as e:
                    label = 'maps_unavailable_errno_%s' % e.errno
                    if label not in item['errors']: log('pid=%s %s' % (pid, label)); item['errors'].add(label)
            except (OSError, ValueError, IndexError):
                continue
        if any(x['env_captured'] and any('libgallium-' in path for path in x['maps']) for x in seen.values()):
            log('watch_complete selected_environment_and_gallium_seen')
            break
        time.sleep(0.1)
    log('watch_finished observed_processes=%d reason=%s' % (len(seen), 'stopped' if stopping else ('timeout' if time.monotonic() >= end else 'captured')))
