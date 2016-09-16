import PackageDescription

let package = Package(
    name: "Bond",
    dependencies: [
        .Package(url: "https://github.com/ReactiveKit/ReactiveKit.git", versions: Version(3, 0, 0, prereleaseIdentifiers: ["beta"])..<Version(4, 0, 0))
    ]
)
