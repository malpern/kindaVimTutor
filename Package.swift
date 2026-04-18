// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "KindaVimTutor",
    platforms: [
        .macOS(.v14),
    ],
    targets: [
        .executableTarget(
            name: "KindaVimTutor",
            path: "Sources/KindaVimTutor",
            exclude: ["Resources/.gitkeep"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "KindaVimTutorTests",
            dependencies: ["KindaVimTutor"],
            path: "Tests/KindaVimTutorTests"
        )
    ]
)
