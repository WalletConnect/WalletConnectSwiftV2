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
	set -o pipefail && xcodebuild -scheme "WalletConnect-Package" -destination "platform=iOS Simulator,name=iPhone 11" -derivedDataPath DerivedDataCache -clonedSourcePackagesDirPath ../SourcePackagesCache RELAY_HOST='$(RELAY_HOST)' PROJECT_ID='$(PROJECT_ID)' build-for-testing | xcpretty
	set -o pipefail && xcodebuild -project "Example/ExampleApp.xcodeproj" -scheme "BuildAll" -destination "platform=iOS Simulator,name=iPhone 11" -derivedDataPath DerivedDataCache -clonedSourcePackagesDirPath ../SourcePackagesCache RELAY_HOST='$(RELAY_HOST)' PROJECT_ID='$(PROJECT_ID)' CAST_HOST='$(CAST_HOST)' build-for-testing | xcpretty

echo_ui_tests:
	echo "EchoUITests disabled"

ui_tests:
	echo "UI Tests disabled"

unit_tests:
	./run_tests.sh --scheme WalletConnect-Package

integration_tests:
	./run_tests.sh --scheme IntegrationTests --testplan IntegrationTests --project Example/ExampleApp.xcodeproj

relay_tests:
	./run_tests.sh --scheme RelayIntegrationTests --project Example/ExampleApp.xcodeproj

notify_tests:
	./run_tests.sh --scheme NotifyTests --project Example/ExampleApp.xcodeproj

smoke_tests:
	./run_tests.sh --scheme IntegrationTests --testplan SmokeTests --project Example/ExampleApp.xcodeproj

release_wallet:
	fastlane release_testflight username:$(APPLE_ID) token:$(TOKEN) relay_host:$(RELAY_HOST) project_id:$(PROJECT_ID) --env WalletApp

release_showcase:
	fastlane release_testflight username:$(APPLE_ID) token:$(TOKEN) relay_host:$(RELAY_HOST) project_id:$(PROJECT_ID) --env Showcase

release_all: 
	fastlane release_testflight username:$(APPLE_ID) token:$(TOKEN) relay_host:$(RELAY_HOST) project_id:$(PROJECT_ID) --env WalletApp
	fastlane release_testflight username:$(APPLE_ID) token:$(TOKEN) relay_host:$(RELAY_HOST) project_id:$(PROJECT_ID) --env Showcase
