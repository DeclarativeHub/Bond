import PackageDescription

let package = Package(
  name: "Bond",
  targets: [
    Target(name: "BNDProtocolProxyBase"),
    Target(name: "Bond", dependencies: ["BNDProtocolProxyBase"])
  ],
  dependencies: [
    .Package(url: "https://github.com/ReactiveKit/ReactiveKit.git", versions: Version(3, 5, 3)..<Version(4, 0, 0)),
    .Package(url: "https://github.com/wokalski/Diff.swift.git", versions: Version(0, 4, 1)..<Version(1, 0, 0))
  ]
)
