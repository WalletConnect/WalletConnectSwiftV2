#!/bin/bash
set -eE
trap 'xcrun simctl delete "$DEVICE_ID"' ERR

# Parse named arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    -s|--scheme) SCHEME="$2"; shift;;
    -p|--project) PROJECT="$2"; shift;;
    -t|--testplan) TESTPLAN="$2"; shift;;
    esac
    shift
done

if [ -z "$SCHEME" ]; then
    echo "No scheme provided"
    exit 1
fi

# Function to update xctestrun file
update_xctestrun() {
    # Parse named arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
        -k|--key) KEY="$2"; shift;;
        -v|--value) VALUE="$2"; shift;;
        -t|--target) TARGET="$2"; shift;;
        esac
        shift
    done

    if [ -n "$VALUE" ]; then
        echo "Updating $KEY with $VALUE"
        plutil -replace TestConfigurations.0.TestTargets.0.EnvironmentVariables.$KEY -string "$VALUE" "$TARGET"
    else
        echo "No value provided for $KEY"
    fi
}

# Set XCBuild defaults
defaults write com.apple.dt.XCBuild IgnoreFileSystemDeviceInodeChanges -bool YES

# Remove and recreate test_results directory
echo "Removing and recreating test_results directory"
rm -rf test_results
mkdir test_results

# Create ephemeral simulator
DEVICE_ID=$(xcrun simctl create "EphemeralSim$SCHEME" "iPhone 14")
echo "Created ephemeral simulator with id: $DEVICE_ID"

if [ -z "$TESTPLAN" ]; then
    XCTESTRUN=$(find . -name "*_$SCHEME*.xctestrun")
else 
    XCTESTRUN=$(find . -name "*_$TESTPLAN*.xctestrun")
fi

# If xctestrun file exists, update it and run test-without-building otherwise run regular test
if [ -z "$XCTESTRUN" ]; then
    echo "XCTESTRUN file not found"

    (
    set -x

    #If xctestrun file does not exist, run regular test
    set -o pipefail && env NSUnbufferedIO=YES \
        xcodebuild \
        ${PROJECT:+-project "$PROJECT"} \
        ${TESTPLAN:+-testPlan "$TESTPLAN"} \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,id=$DEVICE_ID" \
        -derivedDataPath DerivedDataCache \
        -clonedSourcePackagesDirPath ../SourcePackagesCache \
        -resultBundlePath "test_results/$SCHEME.xcresult" \
        test \
        | tee ./test_results/xcodebuild.log \
        | xcbeautify --report junit --junit-report-filename report.junit --report-path ./test_results
    )
else

    echo "XCTESTRUN file found: $XCTESTRUN"

    update_xctestrun --key "RELAY_HOST" --value "$RELAY_HOST" --target "$XCTESTRUN"
    update_xctestrun --key "PROJECT_ID" --value "$PROJECT_ID" --target "$XCTESTRUN"
    update_xctestrun --key "GM_DAPP_PROJECT_ID" --value "$GM_DAPP_PROJECT_ID" --target "$XCTESTRUN"
    update_xctestrun --key "GM_DAPP_PROJECT_SECRET" --value "$GM_DAPP_PROJECT_SECRET" --target "$XCTESTRUN"
    update_xctestrun --key "CAST_HOST" --value "$CAST_HOST" --target "$XCTESTRUN"
    update_xctestrun --key "JS_CLIENT_API_HOST" --value "$JS_CLIENT_API_HOST" --target "$XCTESTRUN"

    (
    set -x

    set -o pipefail && env NSUnbufferedIO=YES \
        xcodebuild \
        -xctestrun "$XCTESTRUN" \
        -destination "platform=iOS Simulator,id=$DEVICE_ID" \
        -derivedDataPath DerivedDataCache \
        -clonedSourcePackagesDirPath ../SourcePackagesCache \
        -resultBundlePath "test_results/$SCHEME.xcresult" \
        test-without-building \
        | tee ./test_results/xcodebuild.log \
        | xcbeautify --report junit --junit-report-filename report.junit --report-path ./test_results
    )
fi  

echo "Removing ephemeral simulator"
xcrun simctl delete "$DEVICE_ID"

echo "Done"
