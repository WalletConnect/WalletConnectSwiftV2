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

build_all:
	rm -rf test_results
	set -o pipefail && xcodebuild -verbose -project "Example/ExampleApp.xcodeproj" -scheme "IntegrationTests" -destination "platform=iOS Simulator,name=iPhone 14" -clonedSourcePackagesDirPath ../SourcePackagesCache -derivedDataPath DerivedDataCache RELAY_HOST='$(RELAY_HOST)' PROJECT_ID='$(PROJECT_ID)' build-for-testing

build_dapp:
	fastlane build scheme:DApp

build_wallet:
	fastlane build scheme:WalletApp

echo_ui_tests:
	fastlane tests scheme:EchoUITests relay_host:$(RELAY_HOST) project_id:$(PROJECT_ID)

ui_tests:
	echo "UI Tests disabled"

unit_tests:
	fastlane tests scheme:WalletConnect

integration_tests:
	defaults write com.apple.dt.XCBuild IgnoreFileSystemDeviceInodeChanges -bool YES
	rm -rf test_results
	set -o pipefail && env NSUnbufferedIO=YES xcodebuild -verbose -destination 'platform=iOS Simulator,name=iPhone 14' -derivedDataPath DerivedDataCache -resultBundlePath 'test_results/IntegrationTests.xcresult' -xctestrun 'DerivedDataCache/Build/Products/IntegrationTests_IntegrationTests_iphonesimulator16.2-x86_64.xctestrun' RELAY_HOST='$(RELAY_HOST)' PROJECT_ID='$(PROJECT_ID)' test-without-building

relay_tests:
	fastlane tests scheme:RelayIntegrationTests relay_host:$(RELAY_HOST) project_id:$(PROJECT_ID)

smoke_tests:
	defaults write com.apple.dt.XCBuild IgnoreFileSystemDeviceInodeChanges -bool YES
	rm -rf test_results
	set -o pipefail && env NSUnbufferedIO=YES xcodebuild -verbose -destination 'platform=iOS Simulator,name=iPhone 14' -derivedDataPath DerivedDataCache -resultBundlePath 'test_results/IntegrationTests.xcresult' -xctestrun 'DerivedDataCache/Build/Products/IntegrationTests_SmokeTests_iphonesimulator16.2-x86_64.xctestrun' RELAY_HOST='$(RELAY_HOST)' PROJECT_ID='$(PROJECT_ID)' test-without-building

resolve_packages: 
	fastlane resolve scheme:WalletApp

release_wallet:
	fastlane release_testflight username:$(APPLE_ID) token:$(TOKEN) relay_host:$(RELAY_HOST) project_id:$(PROJECT_ID) --env WalletApp

release_showcase:
	fastlane release_testflight username:$(APPLE_ID) token:$(TOKEN) relay_host:$(RELAY_HOST) project_id:$(PROJECT_ID) --env Showcase

release_all: 
	fastlane release_testflight username:$(APPLE_ID) token:$(TOKEN) relay_host:$(RELAY_HOST) project_id:$(PROJECT_ID) --env WalletApp
	fastlane release_testflight username:$(APPLE_ID) token:$(TOKEN) relay_host:$(RELAY_HOST) project_id:$(PROJECT_ID) --env Showcase
