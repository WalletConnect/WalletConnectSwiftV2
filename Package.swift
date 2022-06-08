// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "WalletConnect",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "WalletConnect",
            targets: ["WalletConnectSign"]),
    ],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream.git", .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
        .target(
            name: "WalletConnectSign",
            dependencies: ["WalletConnectRelay", "WalletConnectUtils", "WalletConnectKMS"],
            path: "Sources/WalletConnectSign"),
        .target(
            name: "Chat",
            dependencies: ["WalletConnectRelay", "WalletConnectUtils", "WalletConnectKMS"],
            path: "Sources/Chat"),
        .target(
            name: "WalletConnectRelay",
            dependencies: ["WalletConnectUtils", "Starscream"],
            path: "Sources/WalletConnectRelay"),
        .target(
            name: "WalletConnectKMS",
            dependencies: ["WalletConnectUtils"],
            path: "Sources/WalletConnectKMS"),
        .target(
            name: "WalletConnectUtils",
            dependencies: ["Commons"]),
        .target(
            name: "JSONRPC",
            dependencies: ["Commons"]),
        .target(
            name: "Commons",
            dependencies: []),
        .testTarget(
            name: "WalletConnectSignTests",
            dependencies: ["WalletConnectSign", "TestingUtils", "WalletConnectKMS"]),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["WalletConnectSign", "TestingUtils", "WalletConnectKMS"]),
        .testTarget(
            name: "ChatTests",
            dependencies: ["Chat", "WalletConnectUtils", "TestingUtils"]),
        .testTarget(
            name: "RelayerTests",
            dependencies: ["WalletConnectRelay", "WalletConnectUtils", "TestingUtils"]),
        .testTarget(
            name: "WalletConnectKMSTests",
            dependencies: ["WalletConnectKMS", "WalletConnectUtils", "TestingUtils"]),
        .target(
            name: "TestingUtils",
            dependencies: ["WalletConnectUtils", "WalletConnectKMS"],
            path: "Tests/TestingUtils"),
        .testTarget(
            name: "WalletConnectUtilsTests",
            dependencies: ["WalletConnectUtils"]),
        .testTarget(
            name: "JSONRPCTests",
            dependencies: ["JSONRPC", "TestingUtils"]),
        .testTarget(
            name: "CommonsTests",
            dependencies: ["Commons", "TestingUtils"]),
    ],
    swiftLanguageVersions: [.v5]
)
