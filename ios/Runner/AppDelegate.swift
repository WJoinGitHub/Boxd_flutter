import Flutter
import UIKit
import UserNotifications

private let kApnsChannel = "com.qimi.heatlink/apns"

private final class ApnsTokenStore {
  static let shared = ApnsTokenStore()
  var hexToken: String?
  var lastError: String?
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var apnsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// 进入前台或冷启动后首次活跃时清除桌面角标（不依赖 Flutter 引擎是否已就绪）。
  /// 仅改图标数字，不移除通知中心里已送达的通知。
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    if #available(iOS 16.0, *) {
      UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    } else {
      application.applicationIconBadgeNumber = 0
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(name: kApnsChannel, binaryMessenger: messenger)
    apnsChannel = channel

    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "register":
        self?.requestApnsRegistration(result: result)
      case "getDeviceToken":
        result(ApnsTokenStore.shared.hexToken)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func requestApnsRegistration(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if let error = error {
        ApnsTokenStore.shared.lastError = error.localizedDescription
        DispatchQueue.main.async {
          result(FlutterError(code: "auth", message: error.localizedDescription, details: nil))
        }
        return
      }
      if !granted {
        ApnsTokenStore.shared.lastError = "notification permission denied"
        DispatchQueue.main.async {
          result(FlutterError(code: "denied", message: "notification permission denied", details: nil))
        }
        return
      }
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
        result(nil)
      }
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let hex = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    ApnsTokenStore.shared.hexToken = hex
    ApnsTokenStore.shared.lastError = nil
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    ApnsTokenStore.shared.lastError = error.localizedDescription
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.sound, .badge, .banner, .list])
    } else {
      completionHandler([.sound, .badge, .alert])
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }
}
