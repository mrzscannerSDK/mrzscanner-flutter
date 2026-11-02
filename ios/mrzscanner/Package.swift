// swift-tools-version: 5.9
// The Flutter plugin's iOS side for Swift Package Manager: the plugin, the MRZ scanner's iOS SDK
// (Sources/MRZScannerAR) and its core (Frameworks), staged by build.sh. CocoaPods:
// ../mrzscanner.podspec.
import PackageDescription

let package = Package(
    name: "mrzscanner",
    platforms: [.iOS("15.0")],
    products: [.library(name: "mrzscanner", targets: ["mrzscanner"])],
    dependencies: [.package(name: "FlutterFramework", path: "../FlutterFramework")],
    targets: [
        .binaryTarget(name: "MRZScannerCore", path: "Frameworks/MRZScannerCore.xcframework"),
        .target(name: "MRZScannerAR", dependencies: ["MRZScannerCore"], path: "Sources/MRZScannerAR"),
        .target(
            name: "mrzscanner",
            dependencies: [.product(name: "FlutterFramework", package: "FlutterFramework"), "MRZScannerAR"],
            exclude: ["PrivacyInfo.xcprivacy"]
        ),
    ]
)
