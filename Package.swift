// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FeatureUpvotePrebuiltKit",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(
            name: "FeatureUpvotePrebuiltKit",
            targets: ["FeatureUpvotePrebuiltKit"]
        ),
    ],
    dependencies: [
        .package(path: "../FeatureUpvote"),
        .package(path: "../AnalyticsKit"),
        .package(path: "../CommonKitUI"),
        .package(path: "../FoundationX"),
        .package(url: "https://github.com/apple/swift-algorithms", exact: "1.2.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", from: "5.0.1"),
        .package(url: "https://github.com/CombineCommunity/CombineExt", from: "1.8.1")
    ],
    targets: [
        .target(
            name: "FeatureUpvotePrebuiltKit",
            dependencies: [
                "FoundationX",
                "FeatureUpvoteAPIClient",
                "CombineExt",
                .product(name: "FeatureUpvoteKitUI", package: "FeatureUpvote"),
                .product(name: "AnalyticsKit", package: "AnalyticsKit"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "ViewComponent", package: "CommonKitUI"),
            ]
        ),
        .target(
            name: "FeatureUpvoteAPIClient",
            dependencies: [
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
            ]
        )
    ]
)
