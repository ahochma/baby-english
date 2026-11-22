#!/bin/bash
# Build + test on the first available iPhone simulator. Used by CI and runnable locally.
set -euo pipefail
cd "$(dirname "$0")/../ios/App"
UDID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
d = json.load(sys.stdin)["devices"]
runtimes = sorted((k for k in d if "iOS" in k), reverse=True)
for r in runtimes:
    for dev in d[r]:
        if dev["name"].startswith("iPhone"):
            print(dev["udid"]); sys.exit()
sys.exit("no iPhone simulator available")')
echo "Using simulator $UDID"
xcodebuild -version
xcodebuild test \
  -project App.xcodeproj -scheme App \
  -destination "platform=iOS Simulator,id=$UDID" \
  -derivedDataPath "${DERIVED_DATA:-build/DerivedData}" \
  CODE_SIGNING_ALLOWED=NO \
  | tee xcodebuild.log | grep -E "error:|Test Case .*(passed|failed|skipped)|Executed|\*\* (TEST|BUILD)" || true
grep -q "\*\* TEST SUCCEEDED \*\*" xcodebuild.log
