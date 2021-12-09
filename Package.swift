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
        .package(name: "Iridium", url: "https://github.com/llbartekll/iridium.git", .branch("main")),
    ],
    targets: [
        .target(
            name: "WalletConnect",
            dependencies: ["CryptoSwift", "Iridium"]),
        .testTarget(
            name: "WalletConnectTests",
            dependencies: ["WalletConnect"]),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["WalletConnect"]),
    ],
    swiftLanguageVersions: [.v5]
)
