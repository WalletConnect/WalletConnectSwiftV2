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
            name: "WalletConnectRouter",
            targets: ["WalletConnectRouter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/flypaper0/Web3.swift", .branch("master"))
    ],
    targets: [
        .target(
            name: "WalletConnectSign",
            dependencies: ["WalletConnectRelay", "WalletConnectUtils", "WalletConnectKMS", "WalletConnectPairing"],
            path: "Sources/WalletConnectSign"),
        .target(
            name: "Chat",
            dependencies: ["WalletConnectRelay", "WalletConnectUtils", "WalletConnectKMS"],
            path: "Sources/Chat"),
        .target(
            name: "Auth",
            dependencies: [
                "WalletConnectRelay",
                "WalletConnectUtils",
                "WalletConnectKMS",
                "WalletConnectPairing",
                .product(name: "Web3", package: "Web3.swift")
            ],
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
            dependencies: ["WalletConnectUtils"]),
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
            name: "WalletConnectRouter",
            dependencies: []),
        .target(
            name: "Toolbox",
            dependencies: ["WalletConnectUtils", "WalletConnectKMS", "JSONRPC"],
            path: "Tests/Toolbox"),
        .testTarget(
            name: "WalletConnectSignTests",
            dependencies: ["WalletConnectSign", "Toolbox"]),
        .testTarget(
            name: "ChatTests",
            dependencies: ["Chat", "WalletConnectUtils", "Toolbox"]),
        .testTarget(
            name: "AuthTests",
            dependencies: ["Auth", "WalletConnectUtils", "Toolbox"]),
        .testTarget(
            name: "RelayerTests",
            dependencies: ["WalletConnectRelay", "WalletConnectUtils", "Toolbox"]),
        .testTarget(
            name: "WalletConnectKMSTests",
            dependencies: ["WalletConnectKMS", "WalletConnectUtils", "Toolbox"]),
        .testTarget(
            name: "WalletConnectUtilsTests",
            dependencies: ["WalletConnectUtils", "Toolbox"]),
        .testTarget(
            name: "JSONRPCTests",
            dependencies: ["JSONRPC", "Toolbox"]),
        .testTarget(
            name: "CommonsTests",
            dependencies: ["Commons", "Toolbox"])
    ],
    swiftLanguageVersions: [.v5]
)
