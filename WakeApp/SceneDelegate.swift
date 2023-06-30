//
//  SceneDelegate.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/05/27.
//

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.makeKeyAndVisible()
            
            let splashVC = SplashViewController()
            window.rootViewController = splashVC
            
            self.window = window
            
            // 非同期に初期画面をセット
            Task {
                try await Task.sleep(nanoseconds: 1_500_000_000)
                let rootVC = await setRootViewController()
                
                await MainActor.run {
                    let navigationController = UINavigationController(rootViewController: rootVC)
                    window.rootViewController = navigationController
                    
                    if !Network.shared.isOnline() {
                        window.rootViewController?.present(createNetworkErrorAlert(), animated: false)
                    }
                }
            }
        }
    }
    
    func setRootViewController() async -> UIViewController {
        var rootVC: UIViewController = StartingViewController()
        
        guard let currentUser = Auth.auth().currentUser, currentUser.isEmailVerified else {
            return rootVC
        }
        // エラーをキャッチする場合も一律でrootVCを返す
        if let bool = try? await FirebaseFirestoreService().checkDocument(uid: currentUser.uid), bool {
            rootVC = MainTabBarController()
        }
        
        return rootVC
    }
    
    func createNetworkErrorAlert() -> UIAlertController {
        let alertController = UIAlertController(title: "サーバーへ接続が出来ません", message: "WakeAppにアクセスできません。\nインターネット接続を確認してください。", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        return alertController
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

