import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    let shareChannel = FlutterMethodChannel(
      name: "com.packplan.packplan/system_share",
      binaryMessenger: controller.binaryMessenger
    )
    shareChannel.setMethodCallHandler { [weak controller] call, result in
      guard call.method == "shareText" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let text = arguments["text"] as? String,
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "Share text cannot be empty.",
            details: nil
          )
        )
        return
      }

      let activityController = UIActivityViewController(
        activityItems: [text],
        applicationActivities: nil
      )
      if let popover = activityController.popoverPresentationController,
         let view = controller?.view {
        popover.sourceView = view
        popover.sourceRect = CGRect(
          x: view.bounds.midX,
          y: view.bounds.midY,
          width: 0,
          height: 0
        )
        popover.permittedArrowDirections = []
      }
      controller?.present(activityController, animated: true)
      result(nil)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
