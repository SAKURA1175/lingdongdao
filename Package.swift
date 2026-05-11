// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "lingdongdao",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "lingdongdao"
        ),
        .testTarget(
            name: "lingdongdaoTests",
            dependencies: ["lingdongdao"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
