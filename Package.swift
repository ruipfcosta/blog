// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Site",
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
        .package(url: "https://github.com/stencilproject/Stencil.git", exact: "0.15.1"),
        .package(url: "https://github.com/johnsundell/ink.git", exact: "0.6.0")
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
        .executableTarget(
            name: "SiteBuilder",
            dependencies: ["SiteCore", "Stencil"]
        ),
        .testTarget(
            name: "SiteTests",
            dependencies: ["SiteCore"]
        ),
    ]
)
