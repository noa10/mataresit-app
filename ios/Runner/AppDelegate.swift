import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  var flutterEngine: FlutterEngine?
  var fallbackWindow: UIWindow?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("🔥🔥🔥 APP_DELEGATE: Application did finish launching - BASIC TEST")
    NSLog("🔥🔥🔥 APP_DELEGATE: NSLog - Application did finish launching")
    print("🔥🔥🔥 APP_DELEGATE: iOS version: \(UIDevice.current.systemVersion)")
    print("🔥🔥🔥 APP_DELEGATE: Screen bounds: \(UIScreen.main.bounds)")
    NSLog("🔥🔥🔥 APP_DELEGATE: NSLog - iOS version: %@", UIDevice.current.systemVersion)

    // Pre-warm a FlutterEngine
    self.flutterEngine = FlutterEngine(name: "io.flutter", project: nil)
    self.flutterEngine?.run()

    // Register plugins with the engine
    GeneratedPluginRegistrant.register(with: self.flutterEngine!)
    print("🔥🔥🔥 APP_DELEGATE: Flutter engine pre-warmed and plugins registered")
    NSLog("🔥🔥🔥 APP_DELEGATE: NSLog - Flutter engine pre-warmed")

    // FORCE window creation directly in AppDelegate (no SceneDelegate)
    print("🔥🔥🔥 APP_DELEGATE: FORCING direct window creation - no SceneDelegate")
    NSLog("🔥🔥🔥 APP_DELEGATE: NSLog - FORCING direct window creation")

    // Create window immediately
    createWindow()

    // Also schedule a delayed check
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.checkAndCreateWindowIfNeeded()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    print("🔧 APP_DELEGATE: Application did become active")

    // Additional check to ensure window is properly set up
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.checkAndCreateWindowIfNeeded()
    }

    super.applicationDidBecomeActive(application)
  }

  private func checkAndCreateWindowIfNeeded() {
    print("🔧 APP_DELEGATE: Checking if window exists...")

    // Check if any window exists and is properly sized
    var hasValidWindow = false

    if #available(iOS 13.0, *) {
      // Check scene-based windows
      for scene in UIApplication.shared.connectedScenes {
        if let windowScene = scene as? UIWindowScene {
          for window in windowScene.windows {
            if window.isKeyWindow && window.frame.width > 0 && window.frame.height > 0 {
              print("🔧 APP_DELEGATE: Found valid scene window: \(window.frame)")
              hasValidWindow = true
              break
            }
          }
        }
      }
    }

    // Also check traditional window
    if let window = self.fallbackWindow, window.frame.width > 0 && window.frame.height > 0 {
      print("🔧 APP_DELEGATE: Found valid AppDelegate window: \(window.frame)")
      hasValidWindow = true
    }

    if !hasValidWindow {
      print("🔧 APP_DELEGATE: No valid window found, creating one...")
      createWindow()
    } else {
      print("🔧 APP_DELEGATE: Valid window exists, no action needed")
    }
  }

  private func createWindow() {
    print("🔥🔥🔥 APP_DELEGATE: Creating window manually")
    NSLog("🔥🔥🔥 APP_DELEGATE: NSLog - Creating window manually")

    let screenBounds = UIScreen.main.bounds
    print("🔥🔥🔥 APP_DELEGATE: Using screen bounds: \(screenBounds)")
    NSLog("🔥🔥🔥 APP_DELEGATE: NSLog - Screen bounds: %@", screenBounds.debugDescription)

    // Create window with explicit frame
    self.fallbackWindow = UIWindow(frame: screenBounds)
    guard let window = self.fallbackWindow else {
      print("🔥🔥🔥 APP_DELEGATE: ERROR - Failed to create window")
      NSLog("🔥🔥🔥 APP_DELEGATE: NSLog ERROR - Failed to create window")
      return
    }

    // Configure window aggressively
    window.backgroundColor = .systemBackground
    window.isHidden = false
    window.alpha = 1.0
    window.windowLevel = UIWindow.Level.normal

    print("🔥🔥🔥 APP_DELEGATE: Window configured")
    NSLog("🔥🔥🔥 APP_DELEGATE: NSLog - Window configured")

    // Create Flutter view controller
    let flutterVC: FlutterViewController
    if let engine = self.flutterEngine {
      print("🔥🔥🔥 APP_DELEGATE: Using pre-warmed Flutter engine")
      NSLog("🔥🔥🔥 APP_DELEGATE: NSLog - Using pre-warmed Flutter engine")
      flutterVC = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    } else {
      print("🔥🔥🔥 APP_DELEGATE: Creating new Flutter engine")
      NSLog("🔥🔥🔥 APP_DELEGATE: NSLog - Creating new Flutter engine")
      flutterVC = FlutterViewController(project: nil, nibName: nil, bundle: nil)
    }

    // Configure Flutter view controller aggressively
    flutterVC.view.frame = screenBounds
    flutterVC.view.bounds = CGRect(origin: .zero, size: screenBounds.size)
    flutterVC.view.backgroundColor = .systemBackground

    // Set up window hierarchy
    window.rootViewController = flutterVC

    // Make window key and visible AGGRESSIVELY
    window.makeKeyAndVisible()
    window.becomeKey()

    // Force layout
    window.layoutIfNeeded()
    flutterVC.view.layoutIfNeeded()

    print("🔥🔥🔥 APP_DELEGATE: Window created successfully")
    print("🔥🔥🔥 APP_DELEGATE: Window frame: \(window.frame)")
    print("🔥🔥🔥 APP_DELEGATE: Flutter view frame: \(flutterVC.view.frame)")
    print("🔥🔥🔥 APP_DELEGATE: Window is key: \(window.isKeyWindow)")
    print("🔥🔥🔥 APP_DELEGATE: Window is hidden: \(window.isHidden)")

    NSLog("🔥🔥🔥 APP_DELEGATE: NSLog - Window setup complete")
    NSLog("🔥🔥🔥 APP_DELEGATE: NSLog - Window frame: %@", window.frame.debugDescription)
  }

  // MARK: Scene methods DISABLED - using traditional AppDelegate approach

  // Scene-based lifecycle is disabled in Info.plist
  // All window management is handled directly in AppDelegate
}
