// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DroidBridge",
    defaultLocalization: "en",
    platforms: [.macOS("26.0")],
    products: [
        .executable(name: "droidbridge-usb", targets: ["DroidBridgeUSB"]),
        .executable(name: "DroidBridge", targets: ["DroidBridgeApp"]),
    ],
    targets: [
        .systemLibrary(
            name: "CLibMTP",
            pkgConfig: "libmtp",
            providers: [.brew(["libmtp", "pkgconf"])]
        ),
        .target(name: "DroidBridgeCore", resources: [.process("Resources")]),
        .target(name: "DroidBridgeMTP", dependencies: ["DroidBridgeCore", "CLibMTP"]),
        .executableTarget(name: "DroidBridgeUSB", dependencies: ["DroidBridgeMTP", "CLibMTP"]),
        .executableTarget(name: "DroidBridgeApp", dependencies: ["DroidBridgeCore", "DroidBridgeMTP"]),
        .testTarget(name: "DroidBridgeAppTests", dependencies: ["DroidBridgeApp", "DroidBridgeMTP"]),
        .testTarget(name: "DroidBridgeCoreTests", dependencies: ["DroidBridgeCore", "CLibMTP"]),
    ]
)
