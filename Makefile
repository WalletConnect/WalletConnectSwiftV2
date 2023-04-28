XCODE_USER_TEMPLATES_DIR=/Applications/Xcode.app/Contents/Developer/Library/Xcode/Templates/File\ Templates
TEMPLATE_NAME=VIPER
TEMPLATES_DIR=Example/Templates/VIPER

EXISTS_FASTLANE = $(shell command -v fastlane 2> /dev/null)

install_templates:
	mkdir -p $(XCODE_USER_TEMPLATES_DIR)
	rm -fR $(XCODE_USER_TEMPLATES_DIR)/$(TEMPLATE_NAME)
	cp -R $(TEMPLATES_DIR) $(XCODE_USER_TEMPLATES_DIR)

install_env:
ifeq "${EXISTS_FASTLANE}" ""
	@echo Installing fastlane
	sudo gem install fastlane --no-document
endif		
	@echo "All dependencies was installed"

test_setup: 
	defaults write com.apple.dt.XCBuild IgnoreFileSystemDeviceInodeChanges -bool YES
	rm -rf test_results
	mkdir test_results

build_all:
	rm -rf test_results
	set -o pipefail && xcodebuild -scheme "WalletConnect-Package" -destination "platform=iOS Simulator,name=iPhone 14" -derivedDataPath DerivedDataCache -clonedSourcePackagesDirPath ../SourcePackagesCache RELAY_HOST='$(RELAY_HOST)' PROJECT_ID='$(PROJECT_ID)' build-for-testing | xcpretty
	set -o pipefail && xcodebuild -project "Example/ExampleApp.xcodeproj" -scheme "BuildAll" -destination "platform=iOS Simulator,name=iPhone 14" -derivedDataPath DerivedDataCache -clonedSourcePackagesDirPath ../SourcePackagesCache RELAY_HOST='$(RELAY_HOST)' PROJECT_ID='$(PROJECT_ID)' build-for-testing | xcpretty

build_dapp:
	fastlane build scheme:DApp

build_wallet:
	fastlane build scheme:WalletApp

echo_ui_tests:
	echo "EchoUITests disabled"

ui_tests:
	echo "UI Tests disabled"

unitxctestrun = $(shell find . -name '*WalletConnect-Package*.xctestrun')

unit_tests: test_setup
ifneq ($(unitxctestrun),)
	set -o pipefail && env NSUnbufferedIO=YES xcodebuild -destination 'platform=iOS Simulator,name=iPhone 14' -derivedDataPath DerivedDataCache -resultBundlePath 'test_results/UnitTests.xcresult' -xctestrun '$(unitxctestrun)' test-without-building | tee ./test_results/xcodebuild.log | xcpretty --report junit --output ./test_results/report.junit
else
	set -o pipefail && env NSUnbufferedIO=YES xcodebuild -scheme WalletConnect-Package -destination 'platform=iOS Simulator,name=iPhone 14' -derivedDataPath DerivedDataCache -resultBundlePath 'test_results/UnitTests.xcresult' test | tee ./test_results/xcodebuild.log | xcpretty --report junit --output ./test_results/report.junit
endif

integrationxctestrun = $(shell find . -name '*_IntegrationTests*.xctestrun')

integration_tests: test_setup
ifneq ($(integrationxctestrun),)
# override ENV variables
	plutil -replace TestConfigurations.0.TestTargets.0.EnvironmentVariables.RELAY_HOST -string $(RELAY_HOST) $(integrationxctestrun)
	plutil -replace TestConfigurations.0.TestTargets.0.EnvironmentVariables.PROJECT_ID -string $(PROJECT_ID) $(integrationxctestrun)
# test-without-building
	set -o pipefail && env NSUnbufferedIO=YES xcodebuild -destination 'platform=iOS Simulator,name=iPhone 14' -derivedDataPath DerivedDataCache -resultBundlePath 'test_results/IntegrationTests.xcresult' -xctestrun '$(integrationxctestrun)' test-without-building | tee ./test_results/xcodebuild.log | xcpretty --report junit --output ./test_results/report.junit
else
	set -o pipefail && env NSUnbufferedIO=YES xcodebuild -project Example/ExampleApp.xcodeproj -scheme IntegrationTests -testPlan IntegrationTests -destination 'platform=iOS Simulator,name=iPhone 14' -derivedDataPath DerivedDataCache -resultBundlePath 'test_results/IntegrationTests.xcresult' RELAY_HOST='$(RELAY_HOST)' PROJECT_ID='$(PROJECT_ID)' test | tee ./test_results/xcodebuild.log | xcpretty --report junit --output ./test_results/report.junit
endif

relayxctestrun = $(shell find . -name '*_RelayIntegrationTests*.xctestrun')

relay_tests: test_setup
ifneq ($(relayxctestrun),)
# override ENV variables
	plutil -replace TestConfigurations.0.TestTargets.0.EnvironmentVariables.RELAY_HOST -string $(RELAY_HOST) $(relayxctestrun)
	plutil -replace TestConfigurations.0.TestTargets.0.EnvironmentVariables.PROJECT_ID -string $(PROJECT_ID) $(relayxctestrun)
# test-without-building
	set -o pipefail && env NSUnbufferedIO=YES xcodebuild -destination 'platform=iOS Simulator,name=iPhone 14' -derivedDataPath DerivedDataCache -resultBundlePath 'test_results/RelayIntegrationTests.xcresult' -xctestrun '$(relayxctestrun)' test-without-building | tee ./test_results/xcodebuild.log | xcpretty --report junit --output ./test_results/report.junit
else
	set -o pipefail && env NSUnbufferedIO=YES xcodebuild -project Example/ExampleApp.xcodeproj -scheme RelayIntegrationTests -destination 'platform=iOS Simulator,name=iPhone 14' -derivedDataPath DerivedDataCache -resultBundlePath 'test_results/RelayIntegrationTests.xcresult' RELAY_HOST='$(RELAY_HOST)' PROJECT_ID='$(PROJECT_ID)' test | tee ./test_results/xcodebuild.log | xcpretty --report junit --output ./test_results/report.junit
endif

smokexctestrun = $(shell find . -name '*_SmokeTests*.xctestrun')

smoke_tests: test_setup
ifneq ($(smokexctestrun),)
# override ENV variables
	plutil -replace TestConfigurations.0.TestTargets.0.EnvironmentVariables.RELAY_HOST -string $(RELAY_HOST) $(smokexctestrun)
	plutil -replace TestConfigurations.0.TestTargets.0.EnvironmentVariables.PROJECT_ID -string $(PROJECT_ID) $(smokexctestrun)
# test-without-building
	set -o pipefail && env NSUnbufferedIO=YES xcodebuild -destination 'platform=iOS Simulator,name=iPhone 14' -derivedDataPath DerivedDataCache -resultBundlePath 'test_results/SmokeTests.xcresult' -xctestrun '$(smokexctestrun)' test-without-building | tee ./test_results/xcodebuild.log | xcpretty --report junit --output ./test_results/report.junit
else
	set -o pipefail && env NSUnbufferedIO=YES xcodebuild -project Example/ExampleApp.xcodeproj -scheme IntegrationTests -testPlan SmokeTests -destination 'platform=iOS Simulator,name=iPhone 14' -derivedDataPath DerivedDataCache -resultBundlePath 'test_results/SmokeTests.xcresult' RELAY_HOST='$(RELAY_HOST)' PROJECT_ID='$(PROJECT_ID)' test | tee ./test_results/xcodebuild.log | xcpretty --report junit --output ./test_results/report.junit
endif

release_wallet:
	fastlane release_testflight username:$(APPLE_ID) token:$(TOKEN) relay_host:$(RELAY_HOST) project_id:$(PROJECT_ID) --env WalletApp

release_showcase:
	fastlane release_testflight username:$(APPLE_ID) token:$(TOKEN) relay_host:$(RELAY_HOST) project_id:$(PROJECT_ID) --env Showcase

release_all: 
	fastlane release_testflight username:$(APPLE_ID) token:$(TOKEN) relay_host:$(RELAY_HOST) project_id:$(PROJECT_ID) --env WalletApp
	fastlane release_testflight username:$(APPLE_ID) token:$(TOKEN) relay_host:$(RELAY_HOST) project_id:$(PROJECT_ID) --env Showcase
