import Flutter
import UIKit
#if canImport(MRZScannerAR)
import MRZScannerAR   // Swift Package Manager: the SDK is its own module (CocoaPods: the same one)
#endif

/// The MRZ scanner for Flutter: each method passes its string arguments to the SDK's MRZScan and
/// returns its JSON (platforms/API.md); lib/mrzscanner.dart parses it.
public class MrzscannerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "mrzscanner", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(MrzscannerPlugin(), channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String] ?? []
        let arg = { (i: Int) in i < args.count ? args[i] : "" }
        switch call.method {
        case "registerLicense":
            result(MRZScan.registerLicense(arg(0)))
        case "version":
            result(MRZScan.version())
        case "scanImage":
            DispatchQueue.global(qos: .userInitiated).async {
                let json = MRZScan.scanImage(arg(0), options: arg(1))
                DispatchQueue.main.async { result(json) }
            }
        case "scan":
            guard let from = Self.topViewController() else {
                result(FlutterError(code: "view", message: "No view to show the camera over", details: nil))
                return
            }
            MRZScan.present(from: from, settings: arg(0)) { result($0) }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // The view controller on top of the key window (the Flutter view, or what it presents).
    private static func topViewController() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        var top = window?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
