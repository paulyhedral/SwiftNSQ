import PackageDescription

let package = Package(
    name: "SwiftNSQ",
    targets: [],
    dependencies: [
        .Package(url: "https://github.com/danshevluk/SwiftSocket.git", majorVersion: 1),
    ],
    exclude: ["Tests"]
)
