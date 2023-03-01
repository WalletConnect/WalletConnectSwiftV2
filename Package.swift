// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "WalletConnect",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
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
            name: "WalletConnectVerify",
            targets: ["WalletConnectVerify"]),
        .library(
            name: "Web3Inbox",
            targets: ["Web3Inbox"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "WalletConnectSign",
            dependencies: ["WalletConnectPairing"],
            path: "Sources/WalletConnectSign"),
        .target(
            name: "WalletConnectChat",
            dependencies: ["WalletConnectIdentity", "WalletConnectSigner"],
            path: "Sources/Chat"),
        .target(
            name: "Auth",
            dependencies: ["WalletConnectPairing", "WalletConnectSigner"],
            path: "Sources/Auth"),
        .target(
            name: "Web3Wallet",
            dependencies: ["Auth", "WalletConnectSign"],
            path: "Sources/Web3Wallet"),
        .target(
            name: "WalletConnectPush",
            dependencies: ["WalletConnectPairing", "WalletConnectEcho", "WalletConnectNetworking"],
            path: "Sources/WalletConnectPush"),
        .target(
            name: "WalletConnectEcho",
            dependencies: ["WalletConnectNetworking"],
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
            name: "Web3Inbox",
            dependencies: ["WalletConnectChat"]),
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
            name: "WalletConnectNetworking",
            dependencies: ["WalletConnectRelay"]),
        .target(
            name: "WalletConnectRouter",
            dependencies: []),
        .target(
            name: "WalletConnectVerify",
            dependencies: ["WalletConnectUtils"]),
        .testTarget(
            name: "WalletConnectSignTests",
            dependencies: ["WalletConnectSign", "WalletConnectUtils", "TestingUtils"]),
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
            name: "AuthTests",
            dependencies: ["Auth", "WalletConnectUtils", "TestingUtils"]),
        .testTarget(
            name: "RelayerTests",
            dependencies: ["WalletConnectRelay", "WalletConnectUtils", "TestingUtils"]),
        .testTarget(
            name: "VerifyTests",
            dependencies: ["WalletConnectVerify", "TestingUtils"]),
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
            dependencies: ["Commons", "TestingUtils"])
    ],
    swiftLanguageVersions: [.v5]
)
