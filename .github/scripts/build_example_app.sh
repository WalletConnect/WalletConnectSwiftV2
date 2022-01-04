#!/bin/bash

set -eo pipefail
xcodebuild  -project Example/ExampleApp.xcodeproj \
-scheme ExampleApp
-destination platform=iOS\ Simulator,OS=15.1 \
clean