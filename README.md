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

## Migration guide from SignClient and AuthClient to Web3Wallet

### Instantiate client

#### Before
```swift
let metadata = AppMetadata(name: String?,
    description: String?,
    url: String?,
    icons: [String]?
)
Pair.configure(metadata: Metadata)
Auth.configure(signerFactory: SignerFactory)
Networking.configure(projectId: InputConfig.projectId, socketFactory: SocketFactory())
```

#### Now

You need to configure only `Web3Wallet` instance and `Networking`

```swift
let metadata = AppMetadata(name: String?,
    description: String?,
    url: String?,
    icons: [String]?
)
Networking.configure(projectId: InputConfig.projectId, socketFactory: SocketFactory())
Web3Wallet.configure(metadata: metadata, signerFactory: DefaultSignerFactory())
```

### Properties and functions wrappers

#### Before
```swift
    SignClient.sessionProposalPublisher.sink { ... }
```
#### Now
```swift
    Web3WalletClient.sessionProposalPublisher.sink { ... }
```
---
#### Before
```swift
    SignClient.sessionRequestPublisher.sink { ... }
```
#### Now
```swift
    Web3WalletClient.sessionRequestPublisher.sink { ... }
```
---
#### Before
```swift
    AuthClient.authRequestPublisher.sink { ... }
```
#### Now
```swift
    Web3WalletClient.authRequestPublisher.sink { ... }
```
---
#### Before
```swift
    SignClient.sessionsPublisher.sink { ... }
```
#### Now
```swift
    Web3WalletClient.sessionsPublisher.sink { ... }
```
---
#### Before
```swift
    await SignClient.approve(proposalId: proposalId, namespaces: namespaces)
```
#### Now
```swift
    await Web3WalletClient.approve(proposalId: proposalId, namespaces: namespaces)
```
---
#### Before
```swift
    await SignClient.reject(proposalId: proposalId, reason: reason) // For the wallet to reject a session proposal.
```
#### Now
```swift
    await Web3WalletClient.reject(proposalId: proposalId, reason: reason) // For the wallet to reject a session proposal.
```
---
#### Before
```swift
    await AuthClient.reject(requestId: requestId) // For wallet to reject authentication request
```
#### Now
```swift
    await Web3WalletClient.reject(requestId: requestId) // For wallet to reject authentication request
```
---
#### Before
```swift
    await SignClient.update(topic: topic, namespaces: namespaces)
```
#### Now
```swift
    await Web3WalletClient.update(topic: topic, namespaces: namespaces)
```
---
#### Before
```swift
    await SignClient.extend(topic: topic)
```
#### Now
```swift
    await Web3WalletClient.extend(topic: topic)
```
---
#### Before
```swift
    await SignClient.respond(topic: topic, requestId: requestId, response: response)
```
#### Now
```swift
    await Web3WalletClient.respond(topic: topic, requestId: requestId, response: response)
```
---
#### Before
```swift
    await SignClient.emit(topic: topic, event: event, chainId: chainId)
```
#### Now
```swift
    await Web3WalletClient.emit(topic: topic, event: event, chainId: chainId)
```
---
#### Before
```swift
    await PairingClient.pair(uri: uri)
```
#### Now
```swift
    await Web3WalletClient.pair(uri: uri)
```
---
#### Before
```swift
    await SignClient.disconnect(topic: topic)
```
#### Now
```swift
    await Web3WalletClient.disconnect(topic: topic)
```
---
#### Before
```swift
    SignClient.getSessions()
```
#### Now
```swift
    Web3WalletClient.getSessions()
```
---
#### Before
```swift
    AuthClient.formatMessage(payload: payload, address: address)
```
#### Now
```swift
    Web3WalletClient.formatMessage(payload: payload, address: address)
```
---
#### Before
```swift
    await AuthClient.respond(requestId: requestId, signature: signature, from: account)
```
#### Now
```swift
    await Web3WalletClient.respond(requestId: requestId, signature: signature, from: account)
```
---
#### Before
```swift
    SignClient.getPendingRequests(topic: topic)
```
#### Now
```swift
    Web3WalletClient.getPendingRequests(topic: topic)
```
---
#### Before
```swift
    SignClient.getSessionRequestRecord(id: id)
```
#### Now
```swift
    Web3WalletClient.getSessionRequestRecord(id: id)
```
---
#### Before
```swift
    AuthClient.getPendingRequests(account: account)
```
#### Now
```swift
    Web3WalletClient.getPendingRequests(account: account)
```
---

## License

Apache 2.0
