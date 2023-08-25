// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "WalletConnect",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "WalletConnect",
            targets: ["WalletConnectSign"]),
        .library(
            name: "WalletConnectChat",
            targets: ["WalletConnectChat"]),
        .library(
            name: "WalletConnectAuth",
            targets: ["Auth"]),
        .library(
            name: "Web3Wallet",
            targets: ["Web3Wallet"]),
        .library(
            name: "WalletConnectPairing",
            targets: ["WalletConnectPairing"]),
        .library(
            name: "WalletConnectPush",
            targets: ["WalletConnectPush"]),
        .library(
            name: "WalletConnectEcho",
            targets: ["WalletConnectEcho"]),
        .library(
            name: "WalletConnectRouter",
            targets: ["WalletConnectRouter"]),
        .library(
            name: "WalletConnectNetworking",
            targets: ["WalletConnectNetworking"]),
        .library(
            name: "WalletConnectSync",
            targets: ["WalletConnectSync"]),
        .library(
            name: "WalletConnectVerify",
            targets: ["WalletConnectVerify"]),
        .library(
            name: "WalletConnectHistory",
            targets: ["WalletConnectHistory"]),
        .library(
            name: "Web3Inbox",
            targets: ["Web3Inbox"]),
        .library(
            name: "WalletConnectModal",
            targets: ["WalletConnectModal"]),

    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
        .package(url: "https://github.com/WalletConnect/QRCode", from: "14.3.1"),
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.0.4")),
    ],
    targets: [
        .target(
            name: "WalletConnectSign",
            dependencies: ["WalletConnectPairing", "WalletConnectVerify", .product(name: "OrderedCollections", package: "swift-collections")],
            path: "Sources/WalletConnectSign"),
        .target(
            name: "WalletConnectChat",
            dependencies: ["WalletConnectIdentity", "WalletConnectSync", "WalletConnectHistory"],
            path: "Sources/Chat"),
        .target(
            name: "Auth",
            dependencies: ["WalletConnectPairing", "WalletConnectSigner", "WalletConnectVerify"],
            path: "Sources/Auth"),
        .target(
            name: "Web3Wallet",
            dependencies: ["Auth", "WalletConnectSign", "WalletConnectEcho", "WalletConnectVerify"],
            path: "Sources/Web3Wallet"),
        .target(
            name: "WalletConnectPush",
            dependencies: ["WalletConnectPairing", "WalletConnectEcho", "WalletConnectIdentity", "WalletConnectSync", "WalletConnectHistory"],
            path: "Sources/WalletConnectPush"),
        .target(
            name: "WalletConnectEcho",
            dependencies: ["WalletConnectNetworking", "WalletConnectJWT"],
            path: "Sources/WalletConnectEcho"),
        .target(
            name: "WalletConnectRelay",
            dependencies: ["WalletConnectJWT"],
            path: "Sources/WalletConnectRelay",
            resources: [.copy("PackageConfig.json")]),
        .target(
            name: "WalletConnectKMS",
            dependencies: ["WalletConnectUtils"],
            path: "Sources/WalletConnectKMS"),
        .target(
            name: "WalletConnectPairing",
            dependencies: ["WalletConnectNetworking"]),
        .target(
            name: "WalletConnectHistory",
            dependencies: ["HTTPClient", "WalletConnectRelay"]),
        .target(
            name: "Web3Inbox",
            dependencies: ["WalletConnectChat", "WalletConnectPush"]),
        .target(
            name: "WalletConnectSigner",
            dependencies: ["WalletConnectNetworking"]),
        .target(
            name: "WalletConnectJWT",
            dependencies: ["WalletConnectKMS"]),
        .target(
            name: "WalletConnectIdentity",
            dependencies: ["WalletConnectNetworking"]),
        .target(
            name: "WalletConnectUtils",
            dependencies: ["JSONRPC"]),
        .target(
            name: "JSONRPC",
            dependencies: ["Commons"]),
        .target(
            name: "Commons",
            dependencies: []),
        .target(
            name: "HTTPClient",
            dependencies: []),
        .target(
            name: "WalletConnectNetworking",
            dependencies: ["HTTPClient", "WalletConnectRelay"]),
        .target(
            name: "WalletConnectRouter",
            dependencies: []),
        .target(
            name: "WalletConnectVerify",
            dependencies: ["WalletConnectUtils", "WalletConnectNetworking"]),
        .target(
            name: "WalletConnectModal",
            dependencies: ["QRCode", "WalletConnectSign"],
            exclude: ["Secrets/secrets.json.sample"],
            resources: [
                .copy("Secrets/secrets.json"),
                .copy("Resources/Assets.xcassets")
            ]
        ),
        .target(
            name: "WalletConnectSync",
            dependencies: ["WalletConnectSigner"]),
        .testTarget(
            name: "WalletConnectSignTests",
            dependencies: ["WalletConnectSign", "WalletConnectUtils", "TestingUtils", "WalletConnectVerify"]),
        .testTarget(
            name: "Web3WalletTests",
            dependencies: ["Web3Wallet", "TestingUtils"]),
        .testTarget(
            name: "WalletConnectPairingTests",
            dependencies: ["WalletConnectPairing", "TestingUtils"]),
        .testTarget(
            name: "ChatTests",
            dependencies: ["WalletConnectChat", "WalletConnectUtils", "TestingUtils"]),
        .testTarget(
            name: "NotifyTests",
            dependencies: ["WalletConnectPush", "TestingUtils"]),
        .testTarget(
            name: "AuthTests",
            dependencies: ["Auth", "WalletConnectUtils", "TestingUtils", "WalletConnectVerify"]),
        .testTarget(
            name: "RelayerTests",
            dependencies: ["WalletConnectRelay", "WalletConnectUtils", "TestingUtils"]),
        .testTarget(
            name: "VerifyTests",
            dependencies: ["WalletConnectVerify", "TestingUtils", "WalletConnectSign"]),
        .testTarget(
            name: "WalletConnectKMSTests",
            dependencies: ["WalletConnectKMS", "WalletConnectUtils", "TestingUtils"]),
        .target(
            name: "TestingUtils",
            dependencies: ["WalletConnectPairing"],
            path: "Tests/TestingUtils"),
        .testTarget(
            name: "WalletConnectUtilsTests",
            dependencies: ["WalletConnectUtils", "TestingUtils"]),
        .testTarget(
            name: "JSONRPCTests",
            dependencies: ["JSONRPC", "TestingUtils"]),
        .testTarget(
            name: "CommonsTests",
            dependencies: ["Commons", "TestingUtils"]),
        .testTarget(
            name: "WalletConnectModalTests",
            dependencies: ["WalletConnectModal", "TestingUtils"])
    ],
    swiftLanguageVersions: [.v5]
)
