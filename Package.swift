// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "WalletConnect",
    platforms: [
        .iOS("13.0"), .macOS("12.0")
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
