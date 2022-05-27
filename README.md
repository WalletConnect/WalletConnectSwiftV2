![WalletConnect V2](walletconnect-banner.svg)

# WalletConnect v2 - Swift
WalletConnect is an open protocol to communicate securely between Dapps and Wallets. This is the Swift implementation of the protocol for native iOS applications.

## Requirements 
- iOS 13.0+
- Swift  5.5+

## Installation
### Swift Package Manager
1. On Xcode, go to File > Add Packages...
2. Enter the package URL: `https://github.com/WalletConnect/WalletConnectSwiftV2`
3. Click the "Add Package" button.

## Getting Started
Before importing WalletConnect into your code, you need to register a project in [WalletConnect Cloud](https://cloud.walletconnect.com/app).
1. Sign up for a [WalletConnect Cloud](https://cloud.walletconnect.com/app) account.
2. Sign in and click the "+ New Project" button. Give a name to your new project.
3. Inside your project, you will see a Project ID string. Make sure to keep it well secured.

### Project ID
Anyone who registers a project into the cloud application will be granted a Project ID associated with that project. The project ID allows you to start using the relay network immediately, and is needed during SDK initialization.

## Documentation & Usage
To dive deeper into the protocol concepts, check out our documentation:
- [Getting started with wallet integration](https://docs.walletconnect.com/2.0/swift/sign/installation)
- [Protocol Documentation](https://github.com/WalletConnect/walletconnect-specs)
- [Beginner guide to WalletConnect v2.0 for iOS Developers](https://medium.com/walletconnect/beginner-guide-to-walletconnect-v2-0-for-swift-developers-4534b0975218)
- To build the docs for the native client's API, go to **XCode > Product > Build Documentation**


## Where to go from here:
Try our example wallet implementation that is part of WalletConnectSwiftV2 repository. Just open `Example/ExampleApp.xcodeproj`

## License
WalletConnect v2 is released under the Apache 2.0 license. [See LICENSE](https://github.com/WalletConnect/WalletConnectSwiftV2/blob/main/LICENSE) for details.
