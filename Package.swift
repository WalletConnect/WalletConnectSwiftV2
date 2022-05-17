// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "WalletConnect",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "WalletConnect",
            targets: ["WalletConnect"]),
    ],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream.git", .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
        .target(
            name: "WalletConnectAuth",
            dependencies: ["WalletConnectRelay", "WalletConnectUtils", "WalletConnectKMS"],
            path: "Sources/WalletConnectAuth"),
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
            dependencies: []),
        .testTarget(
            name: "WalletConnectTests",
            dependencies: ["WalletConnect", "TestingUtils", "WalletConnectKMS"]),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["WalletConnect", "TestingUtils", "WalletConnectKMS"]),
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
    ],
    swiftLanguageVersions: [.v5]
)
