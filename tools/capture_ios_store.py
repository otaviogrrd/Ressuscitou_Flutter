"""Capture the real bundled app on available iPhone/iPad simulators."""
import json
import os
from pathlib import Path
import subprocess
import struct


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
    if family == 'iPad':
        candidates = [d for d in candidates if 'Pro' in d['name'] and ('13-inch' in d['name'] or '12.9' in d['name'])]
        if not candidates:
            raise SystemExit('No iPad Pro 13-inch/12.9-inch simulator available')
    device = candidates[-1]
    udid = device['udid']
    if device['state'] != 'Booted':
        run('xcrun', 'simctl', 'boot', udid)
    run('xcrun', 'simctl', 'bootstatus', udid, '-b')
    run('xcrun', 'simctl', 'status_bar', udid, 'override', '--time', '9:41',
        '--dataNetwork', 'wifi', '--wifiMode', 'active', '--wifiBars', '3',
        '--batteryState', 'charged', '--batteryLevel', '100')
    run('xcrun', 'simctl', 'ui', udid, 'appearance', 'light')
    target = out / family
    try:
        subprocess.run(
            ['flutter', 'drive', '--debug', '-d', udid,
             '--driver=tools/store_capture_driver.dart',
             '--target=tools/store_capture_test.dart'],
            env={**os.environ, 'STORE_CAPTURE_DIR': str(target.resolve())},
            check=True,
        )
        for screenshot in sorted(target.glob('*.png')):
            width, height = struct.unpack('>II', screenshot.read_bytes()[16:24])
            print(f'{screenshot}: {width} x {height}', flush=True)
            report.append({'device': device['name'], 'file': str(screenshot.relative_to(out)),
                           'width': width, 'height': height})
    finally:
        run('xcrun', 'simctl', 'shutdown', udid)
(out / 'devices.json').write_text(json.dumps(report, indent=2))
