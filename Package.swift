// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WonderlandRuntime",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "WonderlandRuntime",
            targets: ["WonderlandRuntime"]),
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.0")),
        .package(url: "https://github.com/maxxfrazer/FocusEntity.git", .upToNextMajor(from: "2.5.1")),
        .package(url: "https://github.com/maxxfrazer/RealityGeometries.git", .upToNextMajor(from: "1.1.2")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WonderlandRuntime",
            dependencies: ["ZIPFoundation", "FocusEntity", "RealityGeometries"]
        ),
        .testTarget(
            name: "WonderlandRuntimeTests",
            dependencies: ["WonderlandRuntime"]
        ),
    ]
)
