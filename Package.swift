// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "24Frames",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "24Frames",
            targets: ["24Frames"])
    ],
    targets: [
        .target(
            name: "24Frames",
            path: "24Frames",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "24FramesTests",
            dependencies: ["24Frames"],
            path: "24FramesTests"
        )
    ]
)
