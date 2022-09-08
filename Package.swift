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
            targets: ["Chat"]),
        .library(
            name: "WalletConnectAuth",
            targets: ["Auth"]),
        .library(
            name: "WalletConnectRouter",
            targets: ["WalletConnectRouter"]),
        .library(
            name: "WalletConnectNetworking",
            targets: ["WalletConnectNetworking"])
    ],
    dependencies: [
        .package(url: "https://github.com/flypaper0/Web3.swift", .branch("feature/eip-155"))
    ],
    targets: [
        .target(
            name: "WalletConnectSign",
            dependencies: ["WalletConnectNetworking", "WalletConnectPairing"],
            path: "Sources/WalletConnectSign"),
        .target(
            name: "Chat",
            dependencies: ["WalletConnectNetworking"],
            path: "Sources/Chat"),
        .target(
            name: "Auth",
            dependencies: ["WalletConnectPairing", "WalletConnectNetworking", .product(name: "Web3", package: "Web3.swift")],
            path: "Sources/Auth"),
        .target(
            name: "WalletConnectRelay",
            dependencies: ["WalletConnectUtils", "WalletConnectKMS"],
            path: "Sources/WalletConnectRelay"),
        .target(
            name: "WalletConnectKMS",
            dependencies: ["WalletConnectUtils"],
            path: "Sources/WalletConnectKMS"),
        .target(
            name: "WalletConnectPairing",
            dependencies: ["WalletConnectNetworking"]),
        .target(
            name: "WalletConnectUtils",
            dependencies: ["Commons", "JSONRPC"]),
        .target(
            name: "JSONRPC",
            dependencies: ["Commons"]),
        .target(
            name: "Commons",
            dependencies: []),
        .target(
            name: "WalletConnectNetworking",
            dependencies: ["JSONRPC", "WalletConnectKMS", "WalletConnectRelay", "WalletConnectUtils"]),
        .target(
            name: "WalletConnectRouter",
            dependencies: []),
        .testTarget(
            name: "WalletConnectSignTests",
            dependencies: ["WalletConnectSign", "TestingUtils"]),
        .testTarget(
            name: "ChatTests",
            dependencies: ["Chat", "WalletConnectUtils", "TestingUtils"]),
        .testTarget(
            name: "AuthTests",
            dependencies: ["Auth", "WalletConnectUtils", "TestingUtils"]),
        .testTarget(
            name: "RelayerTests",
            dependencies: ["WalletConnectRelay", "WalletConnectUtils", "TestingUtils"]),
        .testTarget(
            name: "WalletConnectKMSTests",
            dependencies: ["WalletConnectKMS", "WalletConnectUtils", "TestingUtils"]),
        .target(
            name: "TestingUtils",
            dependencies: ["WalletConnectPairing", "WalletConnectNetworking"],
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
