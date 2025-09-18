// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "FeatureUpvotePrebuiltKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "FeatureUpvotePrebuiltKit",
            targets: ["FeatureUpvotePrebuiltKit"]
        ),
        .library(
            name: "FUService",
            targets: ["FUService"]
        ),
        .library(
            name: "FeatureUpvoteAPIClient",
            targets: ["FeatureUpvoteAPIClient"]
        ),
    ],
    dependencies: [
        .package(path: "../FeatureUpvote"),
        .package(path: "../AnalyticsKit"),
        .package(path: "../CommonKitUI"),
        .package(path: "../FoundationX"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.1"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", from: "5.0.1"),
        .package(url: "https://github.com/CombineCommunity/CombineExt", from: "1.8.1")
    ],
    targets: [
        .target(
            name: "FeatureUpvotePrebuiltKit",
            dependencies: [
                "FeatureUpvoteAPIClient",
                "CombineExt",
                .product(name: "FeatureUpvoteKitUI", package: "FeatureUpvote"),
                .product(name: "AnalyticsKit", package: "AnalyticsKit"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "ViewComponent", package: "CommonKitUI"),
            ]
        ),
        .target(
            name: "FUService",
            dependencies: ["FoundationX"]
        ),
        .target(
            name: "FeatureUpvoteAPIClient",
            dependencies: [
                "FUService",
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
