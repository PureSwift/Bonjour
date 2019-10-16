// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Bonjour",
    products: [
        .library(
            name: "Bonjour",
            targets: ["Bonjour"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/Bouke/NetService.git",
            from: "0.7.0"
        )
    ],
    targets: [
        .target(
            name: "Bonjour",
            dependencies: []
        ),
        .testTarget(
            name: "BonjourTests",
            dependencies: ["Bonjour"]
        )
    ]
)

#if os(Linux)
package.targets.first(where: { $0.name == "Bonjour" })?.dependencies.append("NetService")
#endif
