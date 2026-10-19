"""Inspect declared DEX classes in a local APK; no signing or network actions."""
import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
import struct
import zipfile

AD_PREFIXES = (
    'Lcom/google/android/gms/ads/', 'Lcom/google/ads/',
    'Lcom/facebook/ads/', 'Lcom/applovin/', 'Lcom/ironsource/',
    'Lcom/unity3d/ads/', 'Lcom/unity3d/services/ads/',
    'Lcom/vungle/', 'Lcom/chartboost/', 'Lcom/inmobi/',
    'Lcom/mbridge/', 'Lcom/bytedance/sdk/openadsdk/',
)


def declared_classes(data):
    if data[:4] != b'dex\n' or len(data) < 112:
        raise ValueError('Unsupported DEX header')
    word = lambda offset: struct.unpack_from('<I', data, offset)[0]
    if word(32) != len(data) or word(36) != 112 or word(40) != 0x12345678:
        raise ValueError('Invalid DEX size or byte order')
    string_count, string_offset = word(56), word(60)
    type_count, type_offset = word(64), word(68)
    class_count, class_offset = word(96), word(100)
    for count, offset, stride in (
        (string_count, string_offset, 4), (type_count, type_offset, 4),
        (class_count, class_offset, 32),
    ):
        if offset + count * stride > len(data):
            raise ValueError('DEX table exceeds file')
    for index in range(class_count):
        type_index = word(class_offset + index * 32)
        if type_index >= type_count:
            raise ValueError('Invalid DEX class type')
        string_index = word(type_offset + type_index * 4)
        if string_index >= string_count:
            raise ValueError('Invalid DEX descriptor index')
        offset = word(string_offset + string_index * 4)
        # Skip the ULEB128 UTF-16 length; descriptors use ASCII for SDK prefixes.
        for _ in range(5):
            byte = data[offset]
            offset += 1
            if byte < 128:
                break
        else:
            raise ValueError('Invalid DEX string length')
        end = data.index(0, offset)
        yield data[offset:end].decode('utf-8', errors='replace')


def audit(apk):
    dex_files, classes = [], set()
    with zipfile.ZipFile(apk) as archive:
        for name in archive.namelist():
            if name.startswith('classes') and name.endswith('.dex') and '/' not in name:
                data = archive.read(name)
                found = set(declared_classes(data))
                dex_files.append({'name': name, 'declaredClasses': len(found),
                                  'sha256': hashlib.sha256(data).hexdigest()})
                classes.update(found)
    if not dex_files:
        raise ValueError('No DEX files in APK')
    matches = sorted(c for c in classes if c.startswith(AD_PREFIXES))
    return {
        'auditedAtUtc': datetime.now(timezone.utc).isoformat(),
        'artifact': str(apk.resolve()),
        'apkSha256': hashlib.sha256(apk.read_bytes()).hexdigest(),
        'dexFiles': dex_files, 'declaredClasses': len(classes),
        'checkedPrefixes': list(AD_PREFIXES), 'adSdkMatches': matches,
        'limitations': [
            'This APK is a local debug build, not the final release AAB.',
            'Prefix scan does not detect unknown or renamed/obfuscated SDKs.',
            'Native libraries, Dart code, production signing and live behavior are outside this scan.',
        ],
    }


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    result = audit(args.apk)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'dexFiles': len(result['dexFiles']),
                      'declaredClasses': result['declaredClasses'],
                      'adSdkMatches': result['adSdkMatches']}))
