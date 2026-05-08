// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MoneyHero",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "MoneyHero",
            targets: ["MoneyHero"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MoneyHero"
        ),
        .testTarget(
            name: "MoneyHeroTests",
            dependencies: ["MoneyHero"]
        )
    ]
)
