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
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.4.1")),
    ],
    targets: [
        .target(
            name: "WalletConnect",
            dependencies: ["CryptoSwift", "Relayer", "WalletConnectUtils"],
            path: "Sources/WalletConnect"),
        .target(
            name: "Relayer",
            dependencies: ["WalletConnectUtils"],
            path: "Sources/Relayer"),
        .target(
            name: "WalletConnectUtils",
            dependencies: []),
        .testTarget(
            name: "WalletConnectTests",
            dependencies: ["WalletConnect"]),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["WalletConnect"]),
        .testTarget(
            name: "RelayerTests",
            dependencies: ["Relayer", "WalletConnectUtils"]),
    ],
    swiftLanguageVersions: [.v5]
)
