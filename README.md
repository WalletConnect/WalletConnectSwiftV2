# Wallet Connect v.2 - Swift

![CI main](https://github.com/WalletConnect/WalletConnectSwiftV2/actions/workflows/ci.yml/badge.svg?branch=main)
![CI develop](https://github.com/WalletConnect/WalletConnectSwiftV2/actions/workflows/ci.yml/badge.svg?branch=develop)

Swift implementation of WalletConnect v.2 protocol for native iOS applications.
## Requirements
- iOS 13
- XCode 13
- Swift 5

## Documentation & Usage
- In order to build API documentation in XCode go to Product -> Build Documentation
- [Getting started with wallet integration](https://docs.walletconnect.com/2.0/swift/sign/installation)
- [Beginner guide to WalletConnect v2.0 for iOS Developers](https://medium.com/walletconnect/beginner-guide-to-walletconnect-v2-0-for-swift-developers-4534b0975218)
- [Protocol Documentation](https://github.com/WalletConnect/walletconnect-specs)
- [Glossary](https://docs.walletconnect.com/2.0/introduction/glossary)
- [Migration guide from Sign and Auth to Web3Wallet](https://github.com/WalletConnect/walletconnect-docs/blob/main/docs/swift/guides/web3wallet-migration.md)


## Installation
### Swift Package Manager
Add .package(url:_:) to your Package.swift:
```Swift
dependencies: [
    .package(url: "https://github.com/WalletConnect/WalletConnectSwiftV2", .branch("main")),
],
```
### Cocoapods
Add pod to your Podfile:

```Ruby
pod 'WalletConnectSwiftV2'
```
If you encounter any problems during package installation, you can specify the exact path to the repository
```Ruby
pod 'WalletConnectSwiftV2', :git => 'https://github.com/WalletConnect/WalletConnectSwiftV2.git', :tag => '1.0.5'
```
## Setting Project ID
Follow instructions from *Configuration.xcconfig* and configure PROJECT_ID with your ID from WalletConnect Dashboard
```
// Uncomment next line and paste your project id. Get this on: https://cloud.walletconnect.com/sign-in
// PROJECT_ID = YOUR_PROJECT_ID
// To use Push Notifications on the Simulator you need to grab the simulator identifier
// from Window->Devices and Simulators->Simulator you're using->Identifier
SIMULATOR_IDENTIFIER = YOUR_SIMULATOR_IDENTIFIER
```
## Example App
open `Example/ExampleApp.xcodeproj`

## Web3Wallet
Web3Wallet SDK introduces a new interface for all wallets that wraps the Sign and Auth clients internally.
- [Migration guide from Sign and Auth to Web3Wallet](https://github.com/WalletConnect/walletconnect-docs/blob/main/docs/swift/web3wallet/upgrade-guide.md)

## License

Apache 2.0
