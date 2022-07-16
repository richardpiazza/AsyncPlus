# AsyncPlus

Swift library that extends async/await concurrency.

<p>
 <img src="https://github.com/richardpiazza/AsyncPlus/workflows/Swift/badge.svg?branch=main" />
 <img src="https://img.shields.io/badge/Swift-5.6-orange.svg" />
 <a href="https://twitter.com/richardpiazza">
 <img src="https://img.shields.io/badge/twitter-@richardpiazza-blue.svg?style=flat" alt="Twitter: @richardpiazza" />
 </a>
</p>

## Usage

**Passthrough Sequences**:

* [`PassthroughAsyncSequence`](Sources/AsyncPlus/PassthroughAsyncSequence.swift)
* [`PassthroughAsyncThrowingSequence`](Sources/AsyncPlus/PassthroughAsyncThrowingSequence.swift)

## Alternatives

* [Swift Async-Algorithms](https://github.com/apple/swift-async-algorithms)
* [AsyncCommunity/AsyncExtensions](https://github.com/AsyncCommunity/AsyncExtensions)

## Installation

This package is distributed using the [Swift Package Manager](https://swift.org/package-manager). 
You can add it using Xcode or by listing it as a dependency in your `Package.swift` manifest:

```swift
let package = Package(
  ...
  dependencies: [
    .package(url: "https://github.com/richardpiazza/AsyncPlus.git", .upToNextMajor(from: "0.1.0")
  ],
  ...
  targets: [
    .target(
      name: "MyPackage",
      dependencies: [
        "AsyncPlus"
      ]
    )
  ]
)
```

## Contribution

Contributions to **AsyncPlus** are welcomed and encouraged! See the [Contribution Guide](CONTRIBUTING.md) for more information.
