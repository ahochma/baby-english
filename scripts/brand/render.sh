#!/bin/bash
# Re-renders the app icon options and the launch screen from the real Pip code.
# Output: scripts/brand/out/icon{A,B,C,D}.png (1024², no alpha) and splash.png (2732²).
# The shipped icon is option D; copy it with:  ./scripts/brand/render.sh --install
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"; ROOT="$DIR/../.."
mkdir -p "$DIR/out" && cd "$DIR/out"
swiftc -parse-as-library -O "$DIR/shim.swift" "$ROOT/ios/App/App/Mascot.swift" "$DIR/icons.swift" -o render
./render
if [ "${1:-}" = "--install" ]; then
  A="$ROOT/ios/App/App/Assets.xcassets"
  cp iconD.png "$A/AppIcon.appiconset/AppIcon-512@2x.png"
  for f in "$A"/Splash.imageset/Default@*.png; do cp splash.png "$f"; done
  cp iconD.png "$ROOT/assets/icon.png"
  sips -Z 512 iconD.png --out "$ROOT/docs/assets/icon.png" >/dev/null
  echo "installed icon D + splash"
fi
