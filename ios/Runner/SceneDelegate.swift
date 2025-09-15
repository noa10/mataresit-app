import UIKit
import Flutter

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    print("🔥🔥🔥 SCENE_DELEGATE: *** SCENE DELEGATE CALLED - BASIC TEST ***")
    NSLog("🔥🔥🔥 SCENE_DELEGATE: NSLog - Scene delegate called")
    print("🔥🔥🔥 SCENE_DELEGATE: Scene: \(scene)")
    print("🔥🔥🔥 SCENE_DELEGATE: Session: \(session)")
    NSLog("🔥🔥🔥 SCENE_DELEGATE: NSLog - Scene and session info logged")

    guard let windowScene = scene as? UIWindowScene else {
      print("🔧 SCENE_DELEGATE: ERROR - Scene is not UIWindowScene")
      return
    }

    print("🔧 SCENE_DELEGATE: Scene will connect - coordinate space: \(windowScene.coordinateSpace.bounds)")
    print("🔧 SCENE_DELEGATE: Window scene screen: \(windowScene.screen.bounds)")

    // Create window with proper bounds
    let window = UIWindow(windowScene: windowScene)

    // Get screen bounds as fallback if scene bounds are zero
    let sceneBounds = windowScene.coordinateSpace.bounds
    let screenBounds = windowScene.screen.bounds
    let mainScreenBounds = UIScreen.main.bounds

    print("🔧 SCENE_DELEGATE: Scene bounds: \(sceneBounds)")
    print("🔧 SCENE_DELEGATE: Window scene screen bounds: \(screenBounds)")
    print("🔧 SCENE_DELEGATE: Main screen bounds: \(mainScreenBounds)")

    // Use the largest available bounds
    var finalBounds = sceneBounds
    if finalBounds.width <= 0 || finalBounds.height <= 0 {
      finalBounds = screenBounds
    }
    if finalBounds.width <= 0 || finalBounds.height <= 0 {
      finalBounds = mainScreenBounds
    }

    print("🔧 SCENE_DELEGATE: Using final bounds: \(finalBounds)")

    // Set window properties with robust sizing
    window.frame = finalBounds
    window.bounds = CGRect(origin: .zero, size: finalBounds.size)
    window.backgroundColor = .white
    window.isHidden = false
    window.alpha = 1.0

    // Create Flutter view controller with pre-warmed engine
    let flutterVC: FlutterViewController
    if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let engine = appDelegate.flutterEngine {
      print("🔧 SCENE_DELEGATE: Using pre-warmed Flutter engine")
      flutterVC = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    } else {
      print("🔧 SCENE_DELEGATE: Creating new Flutter engine")
      flutterVC = FlutterViewController(project: nil, nibName: nil, bundle: nil)
    }

    // Set Flutter view controller frame
    flutterVC.view.frame = finalBounds
    flutterVC.view.bounds = CGRect(origin: .zero, size: finalBounds.size)

    window.rootViewController = flutterVC
    window.makeKeyAndVisible()

    self.window = window

    print("🔧 SCENE_DELEGATE: Window created with frame: \(window.frame)")
    print("🔧 SCENE_DELEGATE: Flutter view frame: \(flutterVC.view.frame)")
    print("🔧 SCENE_DELEGATE: Window is key: \(window.isKeyWindow)")
    print("🔧 SCENE_DELEGATE: Window is hidden: \(window.isHidden)")

    // Schedule additional size checks
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.enforceWindowSize()
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.enforceWindowSize()
    }
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    print("🔧 SCENE_DELEGATE: Scene did become active")
    enforceWindowSize()
  }

  func sceneWillEnterForeground(_ scene: UIScene) {
    print("🔧 SCENE_DELEGATE: Scene will enter foreground")
    enforceWindowSize()
  }

  private func enforceWindowSize() {
    guard let window = self.window else { return }

    let screenBounds = UIScreen.main.bounds
    print("🔧 SCENE_DELEGATE: Enforcing window size - screen bounds: \(screenBounds)")

    // Force window to screen bounds if it has zero size
    if window.frame.width == 0 || window.frame.height == 0 {
      print("🔧 SCENE_DELEGATE: Window has zero size, fixing...")
      window.frame = screenBounds
      window.bounds = CGRect(origin: .zero, size: screenBounds.size)
    }

    window.isHidden = false
    window.alpha = 1.0
    window.makeKeyAndVisible()

    // Update Flutter view controller frame
    if let flutterVC = window.rootViewController as? FlutterViewController {
      flutterVC.view.frame = screenBounds
      flutterVC.view.bounds = CGRect(origin: .zero, size: screenBounds.size)
      flutterVC.view.setNeedsLayout()
      flutterVC.view.layoutIfNeeded()
      print("🔧 SCENE_DELEGATE: Updated Flutter view frame: \(flutterVC.view.frame)")
    }

    print("🔧 SCENE_DELEGATE: Final window frame: \(window.frame)")
  }
}

