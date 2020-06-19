// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DBBBuilder",
    platforms: [.iOS(.v11),
                .macOS(.v10_12)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "DBBBuilder",
            targets: ["DBBBuilder"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "FMDB", url: "https://github.com/ccgus/fmdb", .upToNextMinor(from: "2.7.7")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "DBBBuilder",
            dependencies: ["FMDB", "ExceptionCatcher"],
            path: "Sources/DBBBuilder",
            exclude: ["CodeGenerator", "DBBBuilder-iOS", "DBBBuilder-OSX", "Demos", "Cartfile", "Cartfile.resolved", "DBBBuilder-Bridging-Header.h", "DBBBuilder-Swift.xcworkspace"]
        ),
        .target(name: "ExceptionCatcher"),
        .testTarget(
            name: "DBBBuilderPackageTests",
            dependencies: ["DBBBuilder"]),
    ]
)