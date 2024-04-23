// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pdfkit-playground",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Feature", targets: ["Feature"]),
    ],
    targets: [
        .target(name: "Feature", resources: [.process("./Resources")]),
    ]
)
