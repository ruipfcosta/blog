// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Site",
//    platforms: [
//        .macOS(.v10_15)
//    ],
    products: [
        .executable(
            name: "SiteBuilder",
            targets: ["SiteBuilder"]
        ),
        .library(
            name: "SiteCore",
            targets: ["SiteCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/stencilproject/Stencil.git", .exact("0.14.2")),
        .package(url: "https://github.com/johnsundell/ink.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "SiteCore",
            dependencies: ["Stencil", .product(name: "Ink", package: "ink")],
            resources: [
                .copy("_partials"),
                .copy("_posts"),
                .copy("Content"),
            ]
        ),
        .target(
            name: "SiteBuilder",
            dependencies: ["SiteCore", "Stencil"]
        ),
        .testTarget(
            name: "SiteTests",
            dependencies: ["SiteCore"]
        ),
    ]
)
