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
//        .library(
//            name: "Iridium",
//            targets: ["Iridium"]),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.4.1")),
    ],
    targets: [
        .target(
            name: "WalletConnect",
            dependencies: ["CryptoSwift", "Iridium", "WalletConnectUtils"],
            path: "Sources/WalletConnect"),
        .target(
            name: "Iridium",
            dependencies: ["WalletConnectUtils"],
            path: "Sources/Iridium"),
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
            name: "IridiumTests",
            dependencies: ["Iridium", "WalletConnectUtils"]),
    ],
    swiftLanguageVersions: [.v5]
)
