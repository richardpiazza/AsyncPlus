# AsyncPlus

Swift library extending async/await concurrency features.

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Frichardpiazza%2FAsyncPlus%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/richardpiazza/AsyncPlus)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Frichardpiazza%2FAsyncPlus%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/richardpiazza/AsyncPlus)

## Usage

**Passthrough Sequences**:

* [`PassthroughAsyncSequence`](Sources/AsyncPlus/PassthroughAsyncSequence.swift)
* [`PassthroughAsyncThrowingSequence`](Sources/AsyncPlus/PassthroughAsyncThrowingSequence.swift)

Wrappers around `Async[Throwing]Stream` that maintain continuation/termination logic.

**Passthrough Subjects**

* [`PassthroughAsyncSubject`](Sources/AsyncPlus/PassthroughAsyncSubject.swift)
* [`PassthroughAsyncThrowingSubject`](Sources/AsyncPlus/PassthroughAsyncThrowingSubject.swift)

Swift actor that maintains references to multiple passthrough sequences. This allows for a _shared_ publisher similar to **Combine** `PassthroughSubject`.

**Current Value Subjects**

* [`CurrentValueAsyncSubject`](Sources/AsyncPlus/CurrentValueAsyncSubject.swift)
* [`CurrentValueAsyncThrowingSubject`](Sources/AsyncPlus/CurrentValueAsyncThrowingSubject.swift)

Swift actor that maintains references to multiple streams. This allows for a _shared_ publisher similar to **Combine** `CurrentValueSubject`.

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
    .package(url: "https://github.com/richardpiazza/AsyncPlus.git", .upToNextMajor(from: "0.2.0")
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
