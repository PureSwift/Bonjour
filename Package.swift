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
        ),
        .package(
            url: "https://github.com/Bouke/NetService.git",
            from: "0.8.1"
        )
    ],
    targets: [
        .target(
            name: "Bonjour",
            dependencies: [
                "Socket",
                .product(
                    name: "NetService",
                    package: "NetService",
                    condition: .when(platforms: [.linux])
                )
            ]
        ),
        .testTarget(
            name: "BonjourTests",
            dependencies: ["Bonjour"]
        )
    ]
)
