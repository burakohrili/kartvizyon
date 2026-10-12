import Flutter
import UIKit
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "KartVizyonSubscriptions") {
      let channel = FlutterMethodChannel(
        name: "app.kartvizyon.mobile/subscriptions",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "showManageSubscriptions" else {
          result(FlutterMethodNotImplemented)
          return
        }
        Task { @MainActor in
          guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            result(FlutterError(code: "NO_ACTIVE_SCENE", message: "No active window", details: nil))
            return
          }
          do {
            // StoreKit chooses the correct production or test environment.
            try await AppStore.showManageSubscriptions(in: scene)
            result(nil)
          } catch {
            result(FlutterError(code: "MANAGE_SUBSCRIPTIONS_FAILED", message: "Unable to open subscriptions", details: nil))
          }
        }
      }
    }
  }
}
