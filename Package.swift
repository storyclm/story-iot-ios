// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "StoryIoT",
    platforms: [.macOS(.v10_12),
    			.iOS(.v11)
    ],
    products: [
        .library(
            name: "StoryIoT", targets: ["StoryIoT"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.0.0")),
    ],
    targets: [
        .target(
            name: "StoryIoT",
            dependencies: ["Alamofire"],
            path: "StoryIoT",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "StoryIoT-Tests",
            dependencies: ["StoryIoT"],
            path: "StoryIoTTests",
            exclude: ["Info.plist"]
        )
    ]
)
