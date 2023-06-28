swift package --allow-writing-to-directory ./docs  \
    generate-documentation \
    --target WalletConnectModal \
    --disable-indexing \
    --include-extended-types \
    --output-path ./docs \
    --hosting-base-path WalletConnectSwiftV2 \


# xcodebuild docbuild \
#     -scheme WalletConnectModal \
#     -derivedDataPath ./derivedDataCache \              
#     -destination 'platform=iOS Simulator,name=iPhone 13'

