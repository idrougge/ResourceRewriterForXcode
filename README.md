# Resource Rewriter for Xcode 15+

This plugin lets you automatically rewrite UIKit/SwiftUI image instantations from unreliable string-based inits such as:
```swift
UIImage(named: "some image")
Image("some image")
```
into `ImageResource` literals (as introduced in Xcode 15) such as:
```swift
UIImage(resource: .someImage)
Image(.someImage)
```

## Installation

* In Xcode, go to **File → Add Package Dependencies** and enter the URL for this repository.
* In the following popup, select **Add to Target: None** as the package is for running only in Xcode and not part of your app itself.

![Add to Target: None](https://github.com/idrougge/ResourceRewriterForXcode/assets/17124673/284a44ab-9cb8-402f-bec8-211332fde658)

* In case your application is split into several packages, as is increasingly common, you also need to add the dependency to your package's `Package.swift` file to process images in that package:
```swift
dependencies: [
    .package(url: "https://github.com/idrougge/ResourceRewriterForXcode.git", branch: "main"),
]
```

## Usage

After a rebuild, a secondary click on your project (or package) in the Project Navigator brings up a menu where you will now find the option "Rewrite image resource strings". Select that option and the target where you want your image references to be fixed up.

![Project menu](https://github.com/idrougge/ResourceRewriterForXcode/assets/17124673/604c9023-a9e4-4bb3-8c0e-4af256feb159)

## Cleanup

As the `UIImage(named:)` init returns an optional and `UIImage(resource:)` does not, you may now have `if let`, `guard let` or nil coalescing (`??`) statements that are no longer necessary. These you will have to fix up by yourself as it is beyond the capabilities of a simple plugin.

If you have turned off generated asset symbols, go into your build settings and enable **Generate Asset Symbols** (`ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS`) or the resource names will not resolve.

After you are done, you are free to remove this dependency again, possibly introducing a linter rule forbidding calls to string-based image inits.

## Limitations

* Short-hand calls such as `image = .init(named: "Something")` aren't handled.
* Any image name built with string interpolation or concatenation is untouched as those must be resolved at run-time.
* The plugin strives to follow Xcode's pattern for translating string-based image names into `ImageResource` names but there may be cases where this does not match. Please open an issue in that case so it may added.
* Functions or enums that return or accept string names, as well as wrapper functions or generated code must be rewritten manually if you wish to use `ImageResource` for those. You may fork and customise this plugin if such uses permeate your project.
