// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swift-apple-podcasts",
    // macOS only — the Podcasts store on a Mac is the one this reads.
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "ApplePodcasts", targets: ["ApplePodcasts"]),
    ],
    dependencies: [
        .package(url: "https://github.com/arraypress/swift-sqlite-reader.git", from: "0.1.0"),
    ],
    targets: [
        .target(name: "ApplePodcasts", dependencies: [.product(name: "SQLiteReader", package: "swift-sqlite-reader")]),
        .testTarget(name: "ApplePodcastsTests", dependencies: ["ApplePodcasts"]),
    ]
)

// Swift 7's import rule, today: a file must import every module whose members
// it uses, rather than leaning on another file's imports.
for target in package.targets where target.type != .system && target.type != .binary && target.type != .plugin {
    target.swiftSettings = (target.swiftSettings ?? []) + [.enableUpcomingFeature("MemberImportVisibility")]
}
