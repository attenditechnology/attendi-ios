// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AttendiSpeechService",
    defaultLocalization: "nl",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "AttendiSpeechService",
            targets: ["AttendiSpeechService"]),
    ],
    targets: [
        .target(
            name: "AttendiSpeechService",
            path: "AttendiSpeechService/AttendiSpeechService",
            resources: [.process("Resources")]
        )
    ]
)
