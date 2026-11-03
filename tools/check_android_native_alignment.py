"""Check 16 KB ELF segment alignment of 64-bit native libraries in an APK/AAB."""
import struct
import sys
import zipfile


def check(path):
    failures = []
    count = 0
    with zipfile.ZipFile(path) as archive:
        for name in archive.namelist():
            if not name.endswith('.so') or not any(
                f'/lib/{abi}/' in '/' + name for abi in ('arm64-v8a', 'x86_64')
            ):
                continue
            data = archive.read(name)
            if data[:6] != b'\x7fELF\x02\x01':
                failures.append(f'{name}: unsupported ELF format')
                continue
            count += 1
            offset = struct.unpack_from('<Q', data, 32)[0]
            size, number = struct.unpack_from('<HH', data, 54)
            for index in range(number):
                header = struct.unpack_from('<IIQQQQQQ', data, offset + index * size)
                if header[0] == 1:
                    alignment = header[7]
                    print(f'{name}: LOAD alignment={alignment}')
                    if alignment < 16384 or (header[3] - header[2]) % 16384:
                        failures.append(f'{name}: LOAD segment is not 16 KB aligned')
    if not count:
        failures.append('No 64-bit native libraries found')
    if failures:
        raise SystemExit('\n'.join(failures))
    print(f'PASS: {count} native 64-bit libraries support 16 KB ELF alignment.')


if __name__ == '__main__':
    check(sys.argv[1])
