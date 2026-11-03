"""Builds the web version of the app (installable as a PWA) into
website/reader/, so it deploys with the site at quietquran.com/reader/.

    python tool/build_web.py

Runs `flutter build web` for WebAssembly (with a JavaScript build for
browsers without it), served from /reader/ with everything on our own
server (no CanvasKit from Google's CDN). Then drops the renderers' debug
symbols and writes into sw.js a hash of every file, so the service worker
keeps the app offline and fetches only what changed in a new release.

The folder holds both builds and several renderers; a browser downloads one
of each (about 30 MB on a first visit, most of it the Quran database).
"""

import hashlib
import json
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILD = os.path.join(ROOT, 'build', 'web')
OUT = os.path.join(ROOT, 'website', 'reader')


def main():
    subprocess.run(
        ['flutter', 'build', 'web', '--release', '--wasm',
         '--base-href', '/reader/', '--no-web-resources-cdn'],
        cwd=ROOT, check=True, shell=sys.platform == 'win32')
    shutil.rmtree(OUT, ignore_errors=True)
    shutil.copytree(BUILD, OUT)

    # Not used: Flutter's own service worker (which only removes itself; ours
    # is sw.js) and the renderers' debug symbols.
    for dirpath, _, names in os.walk(OUT):
        for name in names:
            if name == 'flutter_service_worker.js' or name.endswith('.symbols'):
                os.remove(os.path.join(dirpath, name))

    files = {}
    for dirpath, _, names in os.walk(OUT):
        for name in names:
            full = os.path.join(dirpath, name)
            path = os.path.relpath(full, OUT).replace(os.sep, '/')
            if path == 'sw.js' or name.startswith('.'):
                continue
            with open(full, 'rb') as f:
                files[path] = hashlib.sha256(f.read()).hexdigest()[:16]

    sw = os.path.join(OUT, 'sw.js')
    with open(sw, encoding='utf-8') as f:
        text = f.read()
    marker = '{/* FILES */}'
    assert marker in text, 'sw.js has no FILES marker'
    text = text.replace(marker, json.dumps(dict(sorted(files.items())), indent=1))
    with open(sw, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)

    size = sum(os.path.getsize(os.path.join(d, n))
               for d, _, ns in os.walk(OUT) for n in ns)
    print(f'{len(files)} files, {size / 2**20:.1f} MB in {OUT}')


if __name__ == '__main__':
    main()
