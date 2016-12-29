import PackageDescription

let package = Package(
    name: "Bond",
    dependencies: [
        .Package(url: "git@github.com:spire-inc/ReactiveKit.git", versions: Version(3, 1, 3, prereleaseIdentifiers: ["beta"])..<Version(4, 0, 0))
    ]
)
