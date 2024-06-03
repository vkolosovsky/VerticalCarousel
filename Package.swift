// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VerticalCarousel",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "VerticalCarousel",
            targets: ["VerticalCarousel"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "VerticalCarousel",
            path: "Sources"
          )
    ],
    swiftLanguageVersions: [.v5]
)
