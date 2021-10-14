// swift-tools-version:5.3

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
            dependencies: ["CryptoSwift"]),
        .testTarget(
            name: "WalletConnectTests",
            dependencies: ["WalletConnect"]),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["WalletConnect"]),
    ],
    swiftLanguageVersions: [.v5]
)
