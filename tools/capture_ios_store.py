"""Capture the real bundled app on available iPhone/iPad simulators."""
import json
from pathlib import Path
import subprocess
import time


def run(*args):
    return subprocess.check_output(args, text=True)


out = Path('build/store-captures')
out.mkdir(parents=True, exist_ok=True)
devices = json.loads(run('xcrun', 'simctl', 'list', 'devices', 'available', '--json'))
all_devices = [d for group in devices['devices'].values() for d in group]
report = []
for family in ('iPhone', 'iPad'):
    candidates = [d for d in all_devices if d['name'].startswith(family)]
    if not candidates:
        raise SystemExit(f'No available {family} simulator')
    device = candidates[-1]
    udid = device['udid']
    if device['state'] != 'Booted':
        run('xcrun', 'simctl', 'boot', udid)
    run('xcrun', 'simctl', 'bootstatus', udid, '-b')
    run('xcrun', 'simctl', 'status_bar', udid, 'override', '--time', '9:41',
        '--dataNetwork', 'wifi', '--wifiMode', 'active', '--wifiBars', '3',
        '--batteryState', 'charged', '--batteryLevel', '100')
    run('xcrun', 'simctl', 'install', udid, 'build/ios/iphonesimulator/Runner.app')
    # Suppress first-run informational dialogs only; actual app screens are used.
    container = run('xcrun', 'simctl', 'get_app_container', udid,
                    'br.org.cn.ressuscitou', 'data').strip()
    prefs = Path(container) / 'Library/Preferences/br.org.cn.ressuscitou.plist'
    prefs.parent.mkdir(parents=True, exist_ok=True)
    import plistlib
    data = plistlib.loads(prefs.read_bytes()) if prefs.exists() else {}
    data.update({'flutter.TermosIniciaisLidos': True,
                 'flutter.msgTabletLida': True,
                 'flutter.MessageLida': time.strftime('%Y-%m-%d')})
    prefs.write_bytes(plistlib.dumps(data))
    run('xcrun', 'simctl', 'launch', udid, 'br.org.cn.ressuscitou')
    time.sleep(35)
    for appearance in ('light', 'dark'):
        run('xcrun', 'simctl', 'ui', udid, 'appearance', appearance)
        time.sleep(3)
        name = f'{family}-{appearance}.png'
        run('xcrun', 'simctl', 'io', udid, 'screenshot', str(out / name))
        report.append({'device': device['name'], 'file': name})
    run('xcrun', 'simctl', 'shutdown', udid)
(out / 'devices.json').write_text(json.dumps(report, indent=2))
