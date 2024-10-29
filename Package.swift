// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WonderlandRuntime",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "WonderlandRuntime",
            targets: ["WonderlandRuntime"]),
    ],
    dependencies: [
        .package(url: "https://github.com/maxxfrazer/FocusEntity.git", from: "v1.0.0"),
        .package(url: "https://github.com/maxxfrazer/RealityGeometries.git", from: "v1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WonderlandRuntime",
            exclude: ["README.md"]
        ),
        .testTarget(
            name: "WonderlandRuntimeTests",
            dependencies: ["WonderlandRuntime"]
        ),
    ]
)
