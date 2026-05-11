// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VocaFlowShared",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "VocaFlowShared", targets: ["VocaFlowShared"])
    ],
    targets: [
        .target(
            name: "VocaFlowShared",
            path: "Sources/VocaFlowShared"
        )
    ]
)
