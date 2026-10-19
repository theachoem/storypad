// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "storypad_editor",
  platforms: [
    .macOS("10.15")
  ],
  products: [
    .library(name: "storypad-editor", targets: ["storypad_editor"])
  ],
  dependencies: [],
  targets: [
    .target(name: "storypad_editor", dependencies: [])
  ]
)
