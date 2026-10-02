// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "FigureOutYourType",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "TypeCore"),
        .executableTarget(name: "FigureOutYourType", dependencies: ["TypeCore"]),
        .testTarget(name: "TypeCoreTests", dependencies: ["TypeCore"]),
    ]
)
