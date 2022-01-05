#!/bin/bash

bundle exec fastlane gym 
set -eo pipefail
xcodebuild  -project Example/ExampleApp.xcodeproj \
-scheme ExampleApp
-allowProvisioningUpdates \
-destination platform=iOS\ Simulator,OS=15.1 \
clean
