// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "KindaVimTutor",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        // The library holds all views, models, engine, and services.
        // Splitting it out of the executable lets SwiftUI `#Preview` work
        // in Xcode 16+ without needing ENABLE_DEBUG_DYLIB on an executable.
        .library(name: "KindaVimTutorKit", targets: ["KindaVimTutorKit"]),
        .executable(name: "KindaVimTutor", targets: ["KindaVimTutor"]),
    ],
    targets: [
        .target(
            name: "KindaVimTutorKit",
            path: "Sources/KindaVimTutorKit",
            exclude: ["Resources/.gitkeep"]
        ),
        .executableTarget(
            name: "KindaVimTutor",
            dependencies: ["KindaVimTutorKit"],
            path: "Sources/KindaVimTutor"
        ),
        .testTarget(
            name: "KindaVimTutorTests",
            dependencies: ["KindaVimTutorKit"],
            path: "Tests/KindaVimTutorTests"
        )
    ]
)
