// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "Bonjour",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "Bonjour",
            targets: ["Bonjour"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/PureSwift/Socket.git",
            branch: "main"
        )
    ],
    targets: [
        .target(
            name: "Bonjour",
            dependencies: [
                "Socket"
            ]
        ),
        .testTarget(
            name: "BonjourTests",
            dependencies: ["Bonjour"]
        )
    ]
)

#if os(Linux)
package.dependencies.append(.package(url: "https://github.com/Bouke/NetService.git", from: "0.8.1"))
package.targets.first(where: { $0.name == "Bonjour" })?.dependencies.append("NetService")
#endif
