// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Resource Rewriter for Xcode",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .plugin(name: "Rewrite image resource strings", 
                targets: ["Rewrite image resource strings"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "ResourceRewriterForXcode",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ]
        ),
        .plugin(
            name: "Rewrite image resource strings",
            capability: .command(
                intent: .sourceCodeFormatting,
                permissions: [
                    .writeToPackageDirectory(reason:
                        """
                        Your `UIImage(named:)` calls will be rewritten as `UImage(resource:)` calls.
                        Please commit before running.
                        """)
                ]
            ),
            dependencies: [
                .target(name: "ResourceRewriterForXcode"),
            ]
        ),
        .testTarget(
            name: "ResourceRewriterForXcodeTests",
            dependencies: [
                .target(name: "ResourceRewriterForXcode")
            ]
        )
    ]
)
