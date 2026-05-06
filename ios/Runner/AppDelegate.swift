import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    configureFocusLockChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configureFocusLockChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "neuroflow/focus_lock",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      if call.method == "isFocusLockActive" {
        result(UIAccessibility.isGuidedAccessEnabled)
        return
      }

      guard call.method == "setFocusLock" else {
        result(FlutterMethodNotImplemented)
        return
      }

      let arguments = call.arguments as? [String: Any]
      let enabled = arguments?["enabled"] as? Bool ?? false

      if UIAccessibility.isGuidedAccessEnabled == enabled {
        result(true)
        return
      }

      UIAccessibility.requestGuidedAccessSession(enabled: enabled) { success in
        DispatchQueue.main.async {
          result(success)
        }
      }
    }
  }
}
