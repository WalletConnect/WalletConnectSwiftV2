![WalletConnect V2](docs/walletconnect-banner.svg)

# Wallet Connect v2 - Swift
WalletConnect is an open protocol to communicate securely between Dapps and Wallets. This is the Swift implementation of the protocol for native iOS applications.

## Requirements 
- iOS 13.0+
- Swift  5.5+

## Getting Started
Before importing WalletConnect into your code, you need to register a project in [WalletConnect Cloud](https://cloud.walletconnect.com/app).
1. Sign up for a [WalletConnect Cloud](https://cloud.walletconnect.com/app) account.
2. Sign in and click the "+ New Project" button. Give a name to your new project.
3. Inside your project, you will see a Project ID string. Make sure to keep it well secured.

### Project ID
Anyone who registers a project into the cloud application will be granted a Project ID associated with that project. The project ID allows you to start using the relay network immediately, and is needed during SDK initialization.

## Installation
### Swift Package Manager
1. On Xcode, go to File > Add Packages...
2. Enter the package URL: `https://github.com/WalletConnect/WalletConnectSwiftV2`
3. Click the "Add Package" button.

## Initialize WalletConnect in your app
Create an `AppMetadata` object to describe your app. It defines the user-facing information that will be available to peers during active sessions and session proposals.

```swift
import WalletConnect

// Convey your app's brand and identity.
let appMetadata = AppMetadata(
    name: "A Web3 App",
    description: "A cool Web3 app using WalletConnect!",
    url: "example.app.url",
    icons: ["https://example.app.url/icon.png"]
)
```

Initialize a client instance:
```swift
let client = WalletConnectClient(
    metadata: appMetadata,
    projectId: "<YOUR_PROJECT_ID>",
    relayHost: "relay.walletconnect.com"
)
```

In your `UIViewController` class, or anywhere else you choose your app, implement the `WalletConnectClientDelegate` protocol and start listening to the delegate events.
```swift
final class ViewController: UIViewController, WalletConnectClientDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        client.delegate = self
    }
}
```

## Integrating into a wallet
Your wallet should allow users to scan the QR code displayed by Dapps. There is some sample code on how to do this in the example app. Once you have the URI string that was scanned from the QR code, call the `pair(uri:_)` method:
```swift
let uri = "wc:..."
try? client.pair(uri: uri)
```

Listen for the session proposal in the client's delegate:
```swift
func didReceive(sessionProposal: Session.Proposal) {
    // Show the session's information to the user and prompt for approval.
}
```

The `Session.Proposal` object tells all accounts, methods and events required as permissions by the proposing peer to send authorized requests. The session proposal has to be shown to the user, so that it can **approve** or **reject** a session.

### Approval
When approving a session proposal, the client can accept it as it is or add more pre-authorized permissions as needed. All accounts provided must follow the [CAIP-10](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-10.md) standard.
```swift
let accounts = [
    Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
]
client.approve(
    proposal: sessionProposal, // This is the session proposal object received through the delegate.
    accounts: accounts, 
    methods: sessionProposal.methods, 
    events: sessionProposal.events
)
```

### Rejection
If the user rejects the proposal, call the client's `reject` method to tell the peer client to stop waiting for an approval response and hang up the session.
```swift
client.reject(proposal: sessionProposal, reason: .disapprovedChains) // Example reason for rejection.
```

### Settlement
When a session approval is received by the peer client, the approving client will receive the peer's acknowledgement through a settlement delegate call:
```swift
func didSettle(session: Session) {
    // Update the app with the session info.
}
```

The `Session` object carries all the data associated with an active session connection with a Dapp. It is uniquely identified by a `topic`, which can be used to link received requests to an active session. It contains the Dapp's metadata info that can be displayed to the users, all current authorized accounts, methods, events, and the expiration date for when it stays inactive for a long time.

Active sessions can be queried by calling `client.getSettledSessions()`

## Handling requests
During a session's lifetime, a Dapp can request for your wallet users to authorize signing a transaction or a message. These requests are delivered through the `didReceive(sessionRequest:_)` delegate method:
```swift
func didReceive(sessionRequest: Request) {
    // Show the received request in your app.
}
```
When a wallet receives a session request, you want to show it to the user to ask for authorization. Always try to display it in an user-friendly way. The method signature in a received request will always be one of the session's authorized methods. 

The method parameters are delivered through an `AnyCodable` object and can be bound to the expected parameter type by calling the `get(:_)` method:
```swift 
// Get the type expected for a given received method
if sessionRequest.method == "personal_sign" {
    let params = try! sessionRequest.params.get([String].self)
} else if method == "eth_signTypedData" {
    let params = try! sessionRequest.params.get([String].self)
} else if method == "eth_sendTransaction" {
    let params = try! sessionRequest.params.get([EthereumTransaction].self)
}
```

Now, your wallet is responsible for signing the transaction – after all, it has the user's private key. After succesfully signing it, send a response to a Dapp to notify about the authorization:
```swift
let result: AnyCodable = sign(request: sessionRequest) // Sign the transaction in you wallet
let response = JSONRPCResponse<AnyCodable>(id: sessionRequest.id, result: result)
client.respond(topic: sessionRequest.topic, response: .response(response)) // Respond with the result
```

## Web Socket Connection
By default web socket connection is handled internally by the SDK. That means that the web socket will be disconnected when apps go to background and it will connect back when app transitions to foreground. But if it is not the expected behavior for your app and you want to handle socket connection manually, you can do it as follows:
1. Instantiate a Relayer object
```swift
let relayer = Relayer(
    relayHost: "relay.walletconnect.com",
    projectId: "<YOUR_PROJECT_ID>",
    socketConnectionType: .manual
)
```
2. Inject the relayer when initializing a WalletConnectClient instance:
```swift
let client = WalletConnectClient(metadata: metadata, relayer: relayer)
```
3. Control the connection:
```swift
relayer.connect()
```

## Where to go from here:
Try our example wallet implementation that is part of WalletConnectSwiftV2 repository.

To dive deeper into the protocol concepts, check out our documentation:
- To build the docs for the native client's API, go to **XCode > Product > Build Documentation**
- [Protocol Documentation](https://docs.walletconnect.com/2.0/protocol/client-communication)
- [Beginner guide to WalletConnect v2.0 for iOS Developers](https://medium.com/walletconnect/beginner-guide-to-walletconnect-v2-0-for-swift-developers-4534b0975218)
- [Glossary](https://docs.walletconnect.com/2.0/protocol/glossary)

## License
WalletConnect v2 is released under the Apache 2.0 license. [See LICENSE](https://github.com/WalletConnect/WalletConnectSwiftV2/blob/main/LICENSE) for details.