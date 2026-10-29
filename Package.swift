// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MovieSocialApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MovieSocialAppLib",
            targets: ["MovieSocialApp"]
        ),
        .executable(
            name: "MovieSocialApp",
            targets: ["MovieSocialAppRun"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MovieSocialApp",
            dependencies: [],
            path: "Sources"
        ),
        .executableTarget(
            name: "MovieSocialAppRun",
            dependencies: ["MovieSocialApp"],
            path: "AppRunner"
        ),
        .testTarget(
            name: "MovieSocialAppTests",
            dependencies: ["MovieSocialApp"],
            path: "Tests/MovieSocialAppTests"
        ),
    ]
)
