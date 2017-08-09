// swift-tools-version:4.0
import PackageDescription

let package = Package(
  name: "Bond",
  dependencies: [
    .package(url: "https://github.com/ReactiveKit/ReactiveKit.git", .branch("swift-4")),
    .package(url: "https://github.com/wokalski/Diff.swift.git", .branch("swift-4.0"))
  ],
  targets: [
    .target(name: "BNDProtocolProxyBase"),
    .target(name: "Bond", dependencies: ["BNDProtocolProxyBase", "ReactiveKit", "Diff"])
  ]
)
