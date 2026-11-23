#!/bin/bash
#
# Runs the test suite on a simulator.
#
# The simulators that ship with Xcode change between releases, and the "Any ... Simulator
# Device" destinations that Xcode advertises are not runnable, so the device to test on is
# picked from the simulators that are actually installed.
#
# Usage: scripts/test-simulator.sh <platform> <device name prefix>

set -euo pipefail

platform="$1"
name_prefix="$2"

selection=$(xcrun simctl list devices available --json | python3 -c '
import json
import sys

platform, name_prefix = sys.argv[1], sys.argv[2]
runtimes = json.load(sys.stdin)["devices"]


def version(runtime):
    parts = runtime.rsplit(".", 1)[-1].split("-")[1:]
    return tuple(int(part) for part in parts if part.isdigit())


candidates = [
    runtime
    for runtime in runtimes
    if runtime.rsplit(".", 1)[-1].startswith(platform + "-") and runtimes[runtime]
]
if not candidates:
    sys.exit("No " + platform + " simulator is installed")

runtime = max(candidates, key=version)
devices = [device for device in runtimes[runtime] if device["isAvailable"]]
if not devices:
    sys.exit("No " + platform + " simulator is available")

device = next(
    (device for device in devices if device["name"].startswith(name_prefix)),
    devices[0],
)
print(device["udid"], device["name"])
' "$platform" "$name_prefix")

read -r device_udid device_name <<< "$selection"

echo "Testing on $device_name ($platform simulator)"
exec xcodebuild test -scheme SwiftCBOR -destination "platform=$platform Simulator,id=$device_udid"
