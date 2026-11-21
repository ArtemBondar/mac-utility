// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacUtility",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "MacUtility", targets: ["MacUtility"])],
    targets: [.executableTarget(name: "MacUtility")]
)
