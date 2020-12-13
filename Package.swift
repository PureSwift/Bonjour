// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Bonjour",
    products: [
        .library(
            name: "Bonjour",
            targets: ["Bonjour"]
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
package.dependencies.append(.package(url: "https://github.com/Bouke/NetService.git", from: "0.7.0"))
package.targets.first(where: { $0.name == "Bonjour" })?.dependencies.append("NetService")
#endif
