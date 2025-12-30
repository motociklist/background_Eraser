import Flutter
import UIKit
import AppTrackingTransparency
import AdSupport

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Настройка MethodChannel для ATT
    let controller = window?.rootViewController as! FlutterViewController
    let attChannel = FlutterMethodChannel(
      name: "att_service",
      binaryMessenger: controller.binaryMessenger
    )

    attChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "requestTracking" {
        self?.requestTrackingPermission(result: result)
      } else if call.method == "checkStatus" {
        self?.checkTrackingStatus(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func requestTrackingPermission(result: @escaping FlutterResult) {
    if #available(iOS 14, *) {
      ATTrackingManager.requestTrackingAuthorization { status in
        DispatchQueue.main.async {
          let statusString = self.statusToString(status)
          result(statusString)
        }
      }
    } else {
      // Для iOS < 14 всегда разрешено
      result("authorized")
    }
  }

  private func checkTrackingStatus(result: @escaping FlutterResult) {
    if #available(iOS 14, *) {
      let status = ATTrackingManager.trackingAuthorizationStatus
      let statusString = self.statusToString(status)
      result(statusString)
    } else {
      // Для iOS < 14 всегда разрешено
      result("authorized")
    }
  }

  @available(iOS 14, *)
  private func statusToString(_ status: ATTrackingManager.AuthorizationStatus) -> String {
    switch status {
    case .notDetermined:
      return "notDetermined"
    case .restricted:
      return "restricted"
    case .denied:
      return "denied"
    case .authorized:
      return "authorized"
    @unknown default:
      return "notDetermined"
    }
  }
}
